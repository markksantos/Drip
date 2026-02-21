import Foundation
import Drip

/// Persistent storage for hotspot profiles and usage sessions.
/// Thread-safe via a serial dispatch queue. Uses UserDefaults for storage.
public final class UsageStore {

    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.drip.usagestore")

    private enum Keys {
        static let profiles = "drip.profiles"
        static let sessions = "drip.sessions"
    }

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: DripConstants.userDefaultsSuiteName)
            ?? .standard
    }

    // MARK: - Profiles

    public func saveProfiles(_ profiles: [HotspotProfile]) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(profiles) else { return }
            defaults.set(data, forKey: Keys.profiles)
        }
    }

    public func loadProfiles() -> [HotspotProfile] {
        queue.sync {
            guard let data = defaults.data(forKey: Keys.profiles),
                  let profiles = try? JSONDecoder().decode([HotspotProfile].self, from: data)
            else { return [] }
            return profiles
        }
    }

    // MARK: - Sessions

    public func saveSessions(_ sessions: [UsageSession]) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(sessions) else { return }
            defaults.set(data, forKey: Keys.sessions)
        }
    }

    public func loadSessions() -> [UsageSession] {
        queue.sync {
            guard let data = defaults.data(forKey: Keys.sessions),
                  let sessions = try? JSONDecoder().decode([UsageSession].self, from: data)
            else { return [] }
            return sessions
        }
    }

    // MARK: - Maintenance

    public func clearHistory() {
        queue.sync {
            defaults.removeObject(forKey: Keys.sessions)
        }
    }

    public func clearAll() {
        queue.sync {
            defaults.removeObject(forKey: Keys.profiles)
            defaults.removeObject(forKey: Keys.sessions)
        }
    }
}
