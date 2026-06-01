import Foundation
import ServiceManagement

// MARK: - LoginItemManaging

/// Abstraction over the system "launch at login" registration so the view
/// model can be unit-tested without touching `SMAppService` (which requires a
/// registered app bundle and throws when run via `swift run` / from tests).
public protocol LoginItemManaging {
    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool { get }
    /// Register (`true`) or unregister (`false`) the login item.
    /// Returns the resulting enabled state (unchanged on failure).
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool
}

// MARK: - SMAppService implementation

/// Production login-item manager backed by `SMAppService.mainApp` (macOS 13+).
///
/// `SMAppService` only works for a properly bundled, signed app. When the
/// process has no real bundle (e.g. `swift run`, unit tests) registration
/// throws; every call here is guarded so it degrades to a no-op instead of
/// crashing.
public final class SMAppServiceLoginItemManager: LoginItemManaging {

    public init() {}

    private var isBundled: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }

    public var isEnabled: Bool {
        guard isBundled else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Bool {
        guard isBundled else { return false }
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Drip: failed to \(enabled ? "register" : "unregister") login item: \(error.localizedDescription)")
        }
        return isEnabled
    }
}
