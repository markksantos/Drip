import Foundation
import UserNotifications
import Drip

// MARK: - NotificationScheduler Protocol

/// Abstraction over UNUserNotificationCenter for testability.
public protocol NotificationScheduler {
    func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void)
    func scheduleNotification(title: String, body: String, identifier: String)
}

/// Production implementation using UNUserNotificationCenter.
/// Gracefully handles missing app bundle (e.g., when running via `swift run`).
public final class SystemNotificationScheduler: NotificationScheduler {

    private var center: UNUserNotificationCenter?
    private var authorized = false

    public init() {
        // UNUserNotificationCenter.current() crashes without a valid app bundle.
        // Defer access and guard against it.
    }

    private func getCenter() -> UNUserNotificationCenter? {
        if center != nil { return center }
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        do {
            let c = UNUserNotificationCenter.current()
            center = c
            return c
        }
    }

    public func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        guard let center = getCenter() else {
            completionHandler(false, nil)
            return
        }
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            self?.authorized = granted
            completionHandler(granted, error)
        }
    }

    public func scheduleNotification(title: String, body: String, identifier: String) {
        guard authorized, let center = getCenter() else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request)
    }
}

// MARK: - AlertManager

/// Monitors usage against configured data limits and fires macOS notifications
/// when thresholds are crossed. Deduplicates alerts within a billing cycle.
public final class AlertManager {

    private let scheduler: NotificationScheduler
    private var firedThresholds: Set<String> = []
    private var permissionRequested = false

    public init(scheduler: NotificationScheduler = SystemNotificationScheduler()) {
        self.scheduler = scheduler
    }

    /// Check usage for a profile and fire alerts if thresholds are crossed.
    public func checkUsage(for profile: HotspotProfile) {
        ensurePermission()

        guard let limit = profile.dataLimitBytes, limit > 0 else { return }

        let usage = profile.currentUsageBytes
        let fraction = Double(usage) / Double(limit)

        // Check each threshold including the implicit 1.0 (100%)
        var thresholds = profile.alertThresholds
        if !thresholds.contains(1.0) {
            thresholds.append(1.0)
        }
        thresholds.sort()

        for threshold in thresholds {
            guard fraction >= threshold else { continue }

            let key = "\(profile.id.uuidString)-\(threshold)"
            guard !firedThresholds.contains(key) else { continue }

            firedThresholds.insert(key)

            let percent = Int(threshold * 100)
            let usedMB = Double(usage) / 1_048_576.0
            let limitMB = Double(limit) / 1_048_576.0
            let remainingMB = max(0, limitMB - usedMB)

            let title: String
            let body: String

            if threshold >= 1.0 {
                title = "Data Limit Exceeded — \(profile.name)"
                body = String(format: "Used %.1f MB of %.1f MB (%.0f MB over limit)",
                              usedMB, limitMB, usedMB - limitMB)
            } else {
                title = "Data Usage Alert — \(profile.name)"
                body = String(format: "%d%% used: %.1f MB of %.1f MB (%.1f MB remaining)",
                              percent, usedMB, limitMB, remainingMB)
            }

            scheduler.scheduleNotification(title: title, body: body, identifier: key)
        }
    }

    /// Reset fired thresholds for a profile (call on billing cycle reset).
    public func resetThresholds(for profileId: UUID) {
        let prefix = profileId.uuidString
        firedThresholds = firedThresholds.filter { !$0.hasPrefix(prefix) }
    }

    /// Reset all fired thresholds.
    public func resetAllThresholds() {
        firedThresholds.removeAll()
    }

    /// Exposed for testing: check if a threshold has been fired.
    public func hasThresholdFired(profileId: UUID, threshold: Double) -> Bool {
        let key = "\(profileId.uuidString)-\(threshold)"
        return firedThresholds.contains(key)
    }

    private func ensurePermission() {
        guard !permissionRequested else { return }
        permissionRequested = true
        scheduler.requestAuthorization { _, _ in }
    }
}
