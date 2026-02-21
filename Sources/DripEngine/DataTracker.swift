import Foundation
import Combine
import Drip

#if canImport(Darwin)
import Darwin
#endif

// MARK: - NetworkInterfaceProvider Protocol

/// Represents byte counters for a single network interface.
public struct InterfaceStats {
    public let name: String
    public let bytesIn: UInt64
    public let bytesOut: UInt64

    public init(name: String, bytesIn: UInt64, bytesOut: UInt64) {
        self.name = name
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

/// Abstraction over getifaddrs() for testability.
public protocol NetworkInterfaceProvider {
    func interfaceStats() -> [InterfaceStats]
}

/// Production implementation reading system interface counters.
public final class SystemNetworkInterfaceProvider: NetworkInterfaceProvider {

    public init() {}

    public func interfaceStats() -> [InterfaceStats] {
        var results: [InterfaceStats] = []
        var ifaddrsPtr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddrsPtr) == 0, let firstAddr = ifaddrsPtr else {
            return results
        }
        defer { freeifaddrs(ifaddrsPtr) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let addr = cursor {
            let flags = Int32(addr.pointee.ifa_flags)
            // Only include AF_LINK (link-layer) entries that are up
            if addr.pointee.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               flags & IFF_UP != 0,
               let data = addr.pointee.ifa_data {
                let name = String(cString: addr.pointee.ifa_name)
                let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                results.append(InterfaceStats(
                    name: name,
                    bytesIn: UInt64(ifData.ifi_ibytes),
                    bytesOut: UInt64(ifData.ifi_obytes)
                ))
            }
            cursor = addr.pointee.ifa_next
        }
        return results
    }
}

// MARK: - DataTracker

/// Tracks bytes sent/received on the active hotspot interface in real time.
/// Polls system counters and publishes updates via Combine.
public final class DataTracker: ObservableObject {

    /// Current session download bytes.
    @Published public private(set) var sessionBytesDown: Int64 = 0
    /// Current session upload bytes.
    @Published public private(set) var sessionBytesUp: Int64 = 0
    /// Currently tracked interface name.
    @Published public private(set) var activeInterface: String?

    private let interfaceProvider: NetworkInterfaceProvider
    private let store: UsageStore
    private let alertManager: AlertManager
    private let profileManager: ProfileManager

    private var timer: Timer?
    private var baselineBytesIn: UInt64 = 0
    private var baselineBytesOut: UInt64 = 0
    private var lastBytesIn: UInt64 = 0
    private var lastBytesOut: UInt64 = 0
    private var accumulatedIn: Int64 = 0
    private var accumulatedOut: Int64 = 0
    private var currentSession: UsageSession?
    private var currentProfileId: UUID?

    public init(
        interfaceProvider: NetworkInterfaceProvider = SystemNetworkInterfaceProvider(),
        store: UsageStore,
        alertManager: AlertManager,
        profileManager: ProfileManager
    ) {
        self.interfaceProvider = interfaceProvider
        self.store = store
        self.alertManager = alertManager
        self.profileManager = profileManager
    }

    deinit {
        stopTracking()
    }

    // MARK: - Public API

    /// Begin tracking a specific network interface.
    public func startTracking(interfaceName: String, profileId: UUID) {
        stopTracking()

        activeInterface = interfaceName
        currentProfileId = profileId

        // Read baseline counters
        if let stats = currentStats(for: interfaceName) {
            baselineBytesIn = stats.bytesIn
            baselineBytesOut = stats.bytesOut
            lastBytesIn = stats.bytesIn
            lastBytesOut = stats.bytesOut
        }

        accumulatedIn = 0
        accumulatedOut = 0
        sessionBytesDown = 0
        sessionBytesUp = 0

        // Create session
        let session = UsageSession(profileId: profileId, hotspotName: interfaceName)
        currentSession = session

        // Start polling
        timer = Timer.scheduledTimer(withTimeInterval: DripConstants.pollingInterval, repeats: true) { [weak self] _ in
            self?.poll()
        }
    }

    /// Stop tracking and finalize the current session.
    public func stopTracking() {
        timer?.invalidate()
        timer = nil

        if let session = currentSession {
            session.endDate = Date()
            session.bytesDown = sessionBytesDown
            session.bytesUp = sessionBytesUp

            // Save session
            var sessions = store.loadSessions()
            sessions.append(session)
            store.saveSessions(sessions)
        }

        activeInterface = nil
        currentSession = nil
        currentProfileId = nil
        sessionBytesDown = 0
        sessionBytesUp = 0
    }

    /// Total session usage (down + up).
    public var sessionTotalBytes: Int64 {
        sessionBytesDown + sessionBytesUp
    }

    // MARK: - Polling

    private func poll() {
        guard let iface = activeInterface,
              let stats = currentStats(for: iface),
              let profileId = currentProfileId
        else { return }

        // Calculate deltas with rollover handling
        let deltaIn = rollingDelta(current: stats.bytesIn, last: lastBytesIn)
        let deltaOut = rollingDelta(current: stats.bytesOut, last: lastBytesOut)

        lastBytesIn = stats.bytesIn
        lastBytesOut = stats.bytesOut

        accumulatedIn += Int64(deltaIn)
        accumulatedOut += Int64(deltaOut)

        sessionBytesDown = accumulatedIn
        sessionBytesUp = accumulatedOut

        // Update session
        currentSession?.bytesDown = sessionBytesDown
        currentSession?.bytesUp = sessionBytesUp

        // Update profile cumulative usage
        if let profile = profileManager.profile(withId: profileId) {
            let totalDelta = Int64(deltaIn) + Int64(deltaOut)
            profile.currentUsageBytes += totalDelta
            profileManager.persist()

            // Check alerts
            alertManager.checkUsage(for: profile)
        }
    }

    /// Handle 32-bit counter rollover.
    private func rollingDelta(current: UInt64, last: UInt64) -> UInt64 {
        if current >= last {
            return current - last
        }
        // Counter rolled over (32-bit)
        return (UInt64(UInt32.max) - last) + current + 1
    }

    private func currentStats(for interfaceName: String) -> InterfaceStats? {
        interfaceProvider.interfaceStats().first(where: { $0.name == interfaceName })
    }
}
