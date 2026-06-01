import Foundation
import Combine
import Drip

/// DripEngine — the public facade that wires together hotspot detection,
/// data tracking, usage persistence, alerts, and profile management.
public final class DripEngine: ObservableObject {

    public static let version = "0.1.0"

    // MARK: - Components

    public let store: UsageStore
    public let profileManager: ProfileManager
    public let alertManager: AlertManager
    public let dataTracker: DataTracker
    public let hotspotDetector: HotspotDetector

    // MARK: - Published State

    @Published public private(set) var connectionState: ConnectionState = .disconnected
    @Published public private(set) var sessionBytesDown: Int64 = 0
    @Published public private(set) var sessionBytesUp: Int64 = 0

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        store: UsageStore? = nil,
        wifiClient: WiFiClientProtocol? = nil,
        interfaceProvider: NetworkInterfaceProvider? = nil,
        ipDetector: HotspotIPDetector? = nil,
        notificationScheduler: NotificationScheduler? = nil
    ) {
        let s = store ?? UsageStore()
        self.store = s

        let pm = ProfileManager(store: s)
        self.profileManager = pm

        let am = AlertManager(scheduler: notificationScheduler ?? SystemNotificationScheduler())
        self.alertManager = am

        // Share a single interface provider so the data tracker and detector
        // observe the same byte counters during tests and in production.
        let provider = interfaceProvider ?? SystemNetworkInterfaceProvider()

        let dt = DataTracker(
            interfaceProvider: provider,
            store: s,
            alertManager: am,
            profileManager: pm
        )
        self.dataTracker = dt

        let hd = HotspotDetector(
            wifiClient: wifiClient ?? SystemWiFiClient(),
            interfaceProvider: provider,
            ipDetector: ipDetector ?? SystemHotspotIPDetector(),
            dataTracker: dt,
            profileManager: pm
        )
        self.hotspotDetector = hd

        bindPublishers()
    }

    // MARK: - Manual Detection

    /// Force an immediate connection re-check. Exposed so callers (and tests)
    /// can trigger detection without waiting for the polling timer.
    public func refreshConnection() {
        hotspotDetector.checkConnection()
    }

    // MARK: - Lifecycle

    public func start() {
        profileManager.checkResets()
        hotspotDetector.start()
    }

    public func stop() {
        hotspotDetector.stop()
    }

    // MARK: - Convenience

    public var sessionTotalBytes: Int64 {
        sessionBytesDown + sessionBytesUp
    }

    public func loadSessions() -> [UsageSession] {
        store.loadSessions()
    }

    // MARK: - Private

    private func bindPublishers() {
        hotspotDetector.$connectionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)

        dataTracker.$sessionBytesDown
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionBytesDown)

        dataTracker.$sessionBytesUp
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionBytesUp)
    }
}
