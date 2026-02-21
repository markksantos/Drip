import Foundation
import Combine
import Drip
import DripEngine

// MARK: - Display Format

public enum DisplayFormat: String, CaseIterable, Identifiable {
    case gbOnly = "GB only"
    case gbAndPercent = "GB + %"
    case percentOnly = "% only"

    public var id: String { rawValue }
}

// MARK: - Byte Formatting

public struct ByteFormatter {
    private static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        f.countStyle = .binary
        return f
    }()

    public static func string(from bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }

    public static func usageString(
        used: Int64,
        limit: Int64?,
        format: DisplayFormat
    ) -> String {
        let usedStr = string(from: used)
        guard let limit = limit else {
            return usedStr
        }
        let limitStr = string(from: limit)
        let pct = limit > 0 ? Int(Double(used) / Double(limit) * 100) : 0

        switch format {
        case .gbOnly:
            return "\(usedStr) / \(limitStr)"
        case .gbAndPercent:
            return "\(usedStr) / \(limitStr) (\(pct)%)"
        case .percentOnly:
            return "\(pct)%"
        }
    }
}

// MARK: - Usage Level

public enum UsageLevel {
    case normal
    case warning
    case critical

    public static func from(ratio: Double) -> UsageLevel {
        if ratio > 0.9 { return .critical }
        if ratio > 0.75 { return .warning }
        return .normal
    }
}

// MARK: - Fill Level Calculation

public struct FillLevel {
    /// Returns a value between 0.0 and 1.0 representing fill ratio.
    /// Returns 0 when there is no limit (unlimited plan).
    public static func ratio(used: Int64, limit: Int64?) -> Double {
        guard let limit = limit, limit > 0 else { return 0.0 }
        return min(max(Double(used) / Double(limit), 0.0), 1.0)
    }
}

// MARK: - DripViewModel

public final class DripViewModel: ObservableObject {
    @Published public var connectionState: ConnectionState
    @Published public var activeProfile: HotspotProfile?
    @Published public var currentSession: UsageSession?
    @Published public var profiles: [HotspotProfile]
    @Published public var sessionHistory: [UsageSession]
    @Published public var showUsageInMenuBar: Bool
    @Published public var displayFormat: DisplayFormat
    @Published public var launchAtLogin: Bool

    public init(
        connectionState: ConnectionState = .disconnected,
        activeProfile: HotspotProfile? = nil,
        currentSession: UsageSession? = nil,
        profiles: [HotspotProfile] = [],
        sessionHistory: [UsageSession] = [],
        showUsageInMenuBar: Bool = true,
        displayFormat: DisplayFormat = .gbOnly,
        launchAtLogin: Bool = false
    ) {
        self.connectionState = connectionState
        self.activeProfile = activeProfile
        self.currentSession = currentSession
        self.profiles = profiles
        self.sessionHistory = sessionHistory
        self.showUsageInMenuBar = showUsageInMenuBar
        self.displayFormat = displayFormat
        self.launchAtLogin = launchAtLogin
    }

    // MARK: - Computed Properties

    public var isConnected: Bool {
        if case .connected = connectionState { return true }
        return false
    }

    public var connectedHotspotName: String? {
        if case .connected(let name, _) = connectionState { return name }
        return nil
    }

    public var usageRatio: Double {
        guard let profile = activeProfile else { return 0 }
        return FillLevel.ratio(used: profile.currentUsageBytes, limit: profile.dataLimitBytes)
    }

    public var usageLevel: UsageLevel {
        UsageLevel.from(ratio: usageRatio)
    }

    public var formattedUsage: String {
        guard let profile = activeProfile else { return "No data" }
        return ByteFormatter.usageString(
            used: profile.currentUsageBytes,
            limit: profile.dataLimitBytes,
            format: displayFormat
        )
    }

    public var sessionDuration: TimeInterval {
        guard let session = currentSession else { return 0 }
        return (session.endDate ?? Date()).timeIntervalSince(session.startDate)
    }

    public var formattedSessionDuration: String {
        let duration = sessionDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        }
        return String(format: "%dm %02ds", minutes, seconds)
    }

    // MARK: - Actions

    public func resetUsage() {
        activeProfile?.currentUsageBytes = 0
        activeProfile?.lastResetDate = Date()
    }

    public func switchProfile(_ profile: HotspotProfile) {
        activeProfile = profile
    }

    public func addProfile(_ profile: HotspotProfile) {
        profiles.append(profile)
    }

    public func deleteProfile(_ profile: HotspotProfile) {
        profiles.removeAll { $0.id == profile.id }
        if activeProfile?.id == profile.id {
            activeProfile = profiles.first
        }
    }

    public func clearHistory() {
        sessionHistory.removeAll()
    }

    // MARK: - Recent Hotspots (for disconnected view)

    public var recentHotspots: [(name: String, lastUsed: Date)] {
        var seen = Set<String>()
        var result: [(name: String, lastUsed: Date)] = []
        let sorted = sessionHistory.sorted { ($0.endDate ?? $0.startDate) > ($1.endDate ?? $1.startDate) }
        for session in sorted {
            if !seen.contains(session.hotspotName) {
                seen.insert(session.hotspotName)
                result.append((session.hotspotName, session.endDate ?? session.startDate))
            }
        }
        return result
    }

    // MARK: - Engine Binding

    private var engineCancellables = Set<AnyCancellable>()
    private var engine: DripEngine?

    /// Create a view model wired to the real DripEngine.
    public static func live() -> DripViewModel {
        let engine = DripEngine()
        let vm = DripViewModel()
        vm.engine = engine

        // Bind engine state → view model
        engine.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak vm] state in
                vm?.connectionState = state
                if case .connected(let name, _) = state {
                    // Set active profile
                    vm?.activeProfile = engine.profileManager.profileForHotspot(named: name)
                } else {
                    vm?.activeProfile = nil
                    vm?.currentSession = nil
                }
            }
            .store(in: &vm.engineCancellables)

        engine.dataTracker.$sessionBytesDown
            .combineLatest(engine.dataTracker.$sessionBytesUp)
            .receive(on: DispatchQueue.main)
            .sink { [weak vm] down, up in
                if let profile = vm?.activeProfile {
                    // Update session object
                    vm?.currentSession?.bytesDown = down
                    vm?.currentSession?.bytesUp = up
                    // Refresh profile usage to trigger UI updates
                    vm?.objectWillChange.send()
                    _ = profile // keep reference alive
                }
            }
            .store(in: &vm.engineCancellables)

        // Listen for hotspot connect to create session
        NotificationCenter.default.publisher(for: .hotspotConnected)
            .receive(on: DispatchQueue.main)
            .sink { [weak vm] notification in
                guard let name = notification.userInfo?[HotspotNotificationKey.hotspotName] as? String,
                      let profile = vm?.activeProfile else { return }
                vm?.currentSession = UsageSession(profileId: profile.id, hotspotName: name)
            }
            .store(in: &vm.engineCancellables)

        // Listen for disconnect to finalize session
        NotificationCenter.default.publisher(for: .hotspotDisconnected)
            .receive(on: DispatchQueue.main)
            .sink { [weak vm] _ in
                if let session = vm?.currentSession {
                    session.endDate = Date()
                    vm?.sessionHistory.append(session)
                }
                vm?.currentSession = nil
            }
            .store(in: &vm.engineCancellables)

        // Sync profiles list
        engine.profileManager.$profiles
            .receive(on: DispatchQueue.main)
            .assign(to: &vm.$profiles)

        // Load session history from store
        vm.sessionHistory = engine.loadSessions()

        // Start the engine
        engine.start()

        return vm
    }

    // MARK: - Mock Data

    public static func mock() -> DripViewModel {
        let profile = HotspotProfile(
            name: "iPhone Hotspot",
            dataLimitBytes: DripConstants.defaultDataLimitBytes,
            alertThresholds: DripConstants.defaultAlertThresholds,
            resetCycle: .monthly,
            resetDay: 1,
            currentUsageBytes: 4_509_715_660
        )

        let session = UsageSession(
            profileId: profile.id,
            hotspotName: "iPhone Hotspot",
            startDate: Date().addingTimeInterval(-3600),
            bytesDown: 3_326_083_481,
            bytesUp: 1_183_632_179
        )

        let pastSession = UsageSession(
            profileId: profile.id,
            hotspotName: "iPhone Hotspot",
            startDate: Date().addingTimeInterval(-86400 * 2),
            endDate: Date().addingTimeInterval(-86400 * 2 + 7200),
            bytesDown: 2_147_483_648,
            bytesUp: 536_870_912
        )

        return DripViewModel(
            connectionState: .connected(hotspotName: "iPhone Hotspot", interfaceName: "en1"),
            activeProfile: profile,
            currentSession: session,
            profiles: [profile],
            sessionHistory: [session, pastSession],
            showUsageInMenuBar: true,
            displayFormat: .gbOnly,
            launchAtLogin: false
        )
    }

    public static func mockDisconnected() -> DripViewModel {
        let profile = HotspotProfile(
            name: "iPhone Hotspot",
            dataLimitBytes: DripConstants.defaultDataLimitBytes,
            currentUsageBytes: 4_509_715_660
        )

        let pastSession1 = UsageSession(
            profileId: profile.id,
            hotspotName: "iPhone Hotspot",
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date().addingTimeInterval(-86400 + 3600),
            bytesDown: 1_073_741_824,
            bytesUp: 268_435_456
        )

        let pastSession2 = UsageSession(
            profileId: UUID(),
            hotspotName: "Galaxy S24",
            startDate: Date().addingTimeInterval(-86400 * 3),
            endDate: Date().addingTimeInterval(-86400 * 3 + 5400),
            bytesDown: 536_870_912,
            bytesUp: 107_374_182
        )

        return DripViewModel(
            connectionState: .disconnected,
            activeProfile: nil,
            currentSession: nil,
            profiles: [profile],
            sessionHistory: [pastSession1, pastSession2]
        )
    }
}
