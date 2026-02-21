import Foundation
import Combine
import Drip

/// Manages multiple hotspot profiles with auto-creation and billing cycle resets.
public final class ProfileManager: ObservableObject {

    @Published public private(set) var profiles: [HotspotProfile] = []

    private let store: UsageStore
    private var resetTimer: Timer?

    public init(store: UsageStore) {
        self.store = store
        self.profiles = store.loadProfiles()
        checkResets()
        startResetTimer()
    }

    deinit {
        resetTimer?.invalidate()
    }

    // MARK: - Profile Management

    /// Returns the profile for the given hotspot name, creating one if needed.
    @discardableResult
    public func profileForHotspot(named name: String) -> HotspotProfile {
        if let existing = profiles.first(where: { $0.name == name }) {
            return existing
        }
        let profile = HotspotProfile(
            name: name,
            dataLimitBytes: DripConstants.defaultDataLimitBytes,
            alertThresholds: DripConstants.defaultAlertThresholds,
            resetCycle: .monthly
        )
        profiles.append(profile)
        persist()
        return profile
    }

    public func profile(withId id: UUID) -> HotspotProfile? {
        profiles.first(where: { $0.id == id })
    }

    public func updateProfile(_ profile: HotspotProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
        persist()
    }

    public func deleteProfile(withId id: UUID) {
        profiles.removeAll(where: { $0.id == id })
        persist()
    }

    // MARK: - Billing Cycle Resets

    public func checkResets() {
        let now = Date()
        var changed = false
        for profile in profiles {
            if shouldReset(profile: profile, now: now) {
                profile.currentUsageBytes = 0
                profile.lastResetDate = now
                changed = true
            }
        }
        if changed {
            persist()
            objectWillChange.send()
        }
    }

    func shouldReset(profile: HotspotProfile, now: Date) -> Bool {
        let calendar = Calendar.current
        let last = profile.lastResetDate

        switch profile.resetCycle {
        case .daily:
            return !calendar.isDate(last, inSameDayAs: now)
        case .weekly:
            let lastWeek = calendar.component(.weekOfYear, from: last)
            let lastYear = calendar.component(.yearForWeekOfYear, from: last)
            let nowWeek = calendar.component(.weekOfYear, from: now)
            let nowYear = calendar.component(.yearForWeekOfYear, from: now)
            return nowYear > lastYear || nowWeek > lastWeek
        case .monthly:
            let lastMonth = calendar.component(.month, from: last)
            let lastYear = calendar.component(.year, from: last)
            let nowMonth = calendar.component(.month, from: now)
            let nowYear = calendar.component(.year, from: now)
            return nowYear > lastYear || nowMonth > lastMonth
        case .manual:
            return false
        }
    }

    // MARK: - Persistence

    public func persist() {
        store.saveProfiles(profiles)
    }

    // MARK: - Private

    private func startResetTimer() {
        resetTimer = Timer.scheduledTimer(withTimeInterval: DripConstants.pollingInterval * 30, repeats: true) { [weak self] _ in
            self?.checkResets()
        }
    }
}
