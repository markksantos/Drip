import Foundation
import Combine
import Network
import Drip

#if canImport(CoreWLAN)
import CoreWLAN
#endif

// MARK: - WiFiClientProtocol

/// Information about the current WiFi connection.
public struct WiFiInfo {
    public let ssid: String?
    public let bssid: String?
    public let interfaceName: String

    public init(ssid: String?, bssid: String?, interfaceName: String) {
        self.ssid = ssid
        self.bssid = bssid
        self.interfaceName = interfaceName
    }
}

/// Abstraction over CWWiFiClient for testability.
public protocol WiFiClientProtocol {
    func currentWiFiInfo() -> WiFiInfo?
}

#if canImport(CoreWLAN)
/// Production implementation using CoreWLAN.
public final class SystemWiFiClient: WiFiClientProtocol {

    private let client = CWWiFiClient.shared()

    public init() {}

    public func currentWiFiInfo() -> WiFiInfo? {
        guard let iface = client.interface() else { return nil }
        let name = iface.interfaceName ?? "en0"
        let ssid = iface.ssid()
        let bssid = iface.bssid()
        return WiFiInfo(ssid: ssid, bssid: bssid, interfaceName: name)
    }
}
#else
public final class SystemWiFiClient: WiFiClientProtocol {
    public init() {}
    public func currentWiFiInfo() -> WiFiInfo? { return nil }
}
#endif

// MARK: - HotspotIPDetector Protocol

/// Abstraction for detecting hotspot connections by IP address range.
public protocol HotspotIPDetector {
    /// Returns (interfaceName, ipAddress) if any interface has a hotspot IP, or nil.
    func detectHotspotInterface() -> (interfaceName: String, ip: String)?
}

/// Production implementation that reads interface IPs via getifaddrs().
/// iPhone hotspots assign IPs in the 172.20.10.x range — this is the most
/// reliable detection method, independent of SSID/location permissions.
public final class SystemHotspotIPDetector: HotspotIPDetector {
    public init() {}

    public func detectHotspotInterface() -> (interfaceName: String, ip: String)? {
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrsPtr) == 0, let first = ifaddrsPtr else { return nil }
        defer { freeifaddrs(ifaddrsPtr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = cursor {
            defer { cursor = addr.pointee.ifa_next }

            guard addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_INET) else { continue }

            let flags = Int32(addr.pointee.ifa_flags)
            guard flags & IFF_UP != 0, flags & IFF_RUNNING != 0 else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr.pointee.ifa_addr,
                        socklen_t(addr.pointee.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, 0, NI_NUMERICHOST)
            let ip = String(cString: hostname)
            let name = String(cString: addr.pointee.ifa_name)

            // iPhone hotspot: 172.20.10.x
            if ip.hasPrefix("172.20.10.") {
                return (interfaceName: name, ip: ip)
            }
        }
        return nil
    }
}

// MARK: - Notification Names

public extension Notification.Name {
    static let hotspotConnected = Notification.Name("com.drip.hotspotConnected")
    static let hotspotDisconnected = Notification.Name("com.drip.hotspotDisconnected")
}

public enum HotspotNotificationKey {
    public static let hotspotName = "hotspotName"
    public static let interfaceName = "interfaceName"
}

// MARK: - HotspotDetector

/// Detects when the Mac connects to an iPhone hotspot via WiFi, USB, or Bluetooth.
///
/// Detection strategy (in priority order):
/// 1. **IP range check** — iPhone hotspots assign 172.20.10.x IPs. This is the most
///    reliable method and works without location permission or SSID access.
/// 2. **SSID check** — If CoreWLAN returns an SSID (requires location permission on
///    macOS 14+), match against known hotspot name patterns.
/// 3. **Bluetooth PAN** — Check for bnep/pan interfaces.
///
/// Posts notifications on connect/disconnect and manages the DataTracker lifecycle.
public final class HotspotDetector: ObservableObject {

    @Published public private(set) var connectionState: ConnectionState = .disconnected

    private let wifiClient: WiFiClientProtocol
    private let interfaceProvider: NetworkInterfaceProvider
    private let ipDetector: HotspotIPDetector
    private let dataTracker: DataTracker
    private let profileManager: ProfileManager

    private var pathMonitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "com.drip.hotspotdetector")
    private var pollTimer: Timer?

    /// Known iPhone hotspot SSID patterns.
    private static let hotspotPatterns = ["iphone", "ipad", "'s iphone", "'s ipad"]

    public init(
        wifiClient: WiFiClientProtocol = SystemWiFiClient(),
        interfaceProvider: NetworkInterfaceProvider = SystemNetworkInterfaceProvider(),
        ipDetector: HotspotIPDetector = SystemHotspotIPDetector(),
        dataTracker: DataTracker,
        profileManager: ProfileManager
    ) {
        self.wifiClient = wifiClient
        self.interfaceProvider = interfaceProvider
        self.ipDetector = ipDetector
        self.dataTracker = dataTracker
        self.profileManager = profileManager
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    public func start() {
        startPathMonitor()
        startPolling()
        checkConnection()
    }

    public func stop() {
        pathMonitor?.cancel()
        pathMonitor = nil
        pollTimer?.invalidate()
        pollTimer = nil

        if case .connected = connectionState {
            disconnect()
        }
    }

    // MARK: - Detection Logic

    /// Main detection check — called periodically and on network path changes.
    public func checkConnection() {
        // 1. IP range detection (most reliable — works without location permission)
        //    iPhone hotspots always assign 172.20.10.x addresses.
        if let hotspot = ipDetector.detectHotspotInterface() {
            // Try to get the SSID for a friendly name; fall back to "iPhone Hotspot"
            let name: String
            if let wifi = wifiClient.currentWiFiInfo(),
               let ssid = wifi.ssid, !ssid.isEmpty,
               wifi.interfaceName == hotspot.interfaceName {
                name = ssid
            } else {
                name = "iPhone Hotspot"
            }
            handleConnected(hotspotName: name, interfaceName: hotspot.interfaceName)
            return
        }

        // 2. SSID-based detection (fallback for non-standard hotspot IP ranges)
        if let wifi = wifiClient.currentWiFiInfo(),
           let ssid = wifi.ssid,
           isHotspotSSID(ssid) {
            handleConnected(hotspotName: ssid, interfaceName: wifi.interfaceName)
            return
        }

        // 3. Bluetooth PAN
        if let btInterface = detectBluetoothPAN() {
            handleConnected(hotspotName: "Bluetooth Tethering", interfaceName: btInterface)
            return
        }

        // No hotspot found
        if case .connected = connectionState {
            disconnect()
        }
    }

    /// Check if an SSID looks like an iPhone/iPad hotspot.
    public func isHotspotSSID(_ ssid: String) -> Bool {
        let lower = ssid.lowercased()
        return Self.hotspotPatterns.contains(where: { lower.contains($0) })
    }

    /// Detect Bluetooth PAN interfaces.
    func detectBluetoothPAN() -> String? {
        let stats = interfaceProvider.interfaceStats()
        for s in stats {
            if s.name.hasPrefix("bnep") || s.name.hasPrefix("pan") {
                return s.name
            }
        }
        return nil
    }

    // MARK: - State Management

    private func handleConnected(hotspotName: String, interfaceName: String) {
        let newState = ConnectionState.connected(hotspotName: hotspotName, interfaceName: interfaceName)

        // Already connected to this hotspot
        if connectionState == newState { return }

        // Disconnect previous if switching
        if case .connected = connectionState {
            disconnect()
        }

        connectionState = newState

        // Auto-create or get profile
        let profile = profileManager.profileForHotspot(named: hotspotName)

        // Start data tracking
        dataTracker.startTracking(interfaceName: interfaceName, profileId: profile.id)

        // Post notification
        NotificationCenter.default.post(
            name: .hotspotConnected,
            object: self,
            userInfo: [
                HotspotNotificationKey.hotspotName: hotspotName,
                HotspotNotificationKey.interfaceName: interfaceName
            ]
        )
    }

    private func disconnect() {
        guard case let .connected(hotspotName, interfaceName) = connectionState else { return }

        dataTracker.stopTracking()
        connectionState = .disconnected

        NotificationCenter.default.post(
            name: .hotspotDisconnected,
            object: self,
            userInfo: [
                HotspotNotificationKey.hotspotName: hotspotName,
                HotspotNotificationKey.interfaceName: interfaceName
            ]
        )
    }

    // MARK: - Monitoring

    private func startPathMonitor() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkConnection()
            }
        }
        pathMonitor?.start(queue: monitorQueue)
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: DripConstants.pollingInterval, repeats: true) { [weak self] _ in
            self?.checkConnection()
        }
    }
}
