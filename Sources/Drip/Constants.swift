import Foundation

public enum DripConstants {
    /// Default data limit: 10 GB
    public static let defaultDataLimitBytes: Int64 = 10_737_418_240

    /// Polling interval in seconds for network stats
    public static let pollingInterval: TimeInterval = 2.0

    /// Minimum supported macOS version
    public static let minimumMacOSVersion: Double = 13.0

    /// App bundle identifier
    public static let bundleIdentifier: String = "com.drip.app"

    /// UserDefaults suite name for shared preferences
    public static let userDefaultsSuiteName: String = "com.drip.app.defaults"

    /// Default alert thresholds (percentage of data limit)
    public static let defaultAlertThresholds: [Double] = [0.5, 0.75, 0.9]
}
