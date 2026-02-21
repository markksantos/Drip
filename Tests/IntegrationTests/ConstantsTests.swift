import XCTest
@testable import Drip

final class ConstantsTests: XCTestCase {

    func testDefaultDataLimitIs10GB() {
        // 10 GB = 10 * 1024 * 1024 * 1024 = 10,737,418,240 bytes
        XCTAssertEqual(DripConstants.defaultDataLimitBytes, 10_737_418_240)
    }

    func testPollingIntervalIsPositive() {
        XCTAssertGreaterThan(DripConstants.pollingInterval, 0)
        XCTAssertEqual(DripConstants.pollingInterval, 2.0)
    }

    func testMinimumMacOSVersion() {
        XCTAssertEqual(DripConstants.minimumMacOSVersion, 13.0)
    }

    func testBundleIdentifier() {
        XCTAssertFalse(DripConstants.bundleIdentifier.isEmpty)
        XCTAssertEqual(DripConstants.bundleIdentifier, "com.drip.app")
    }

    func testUserDefaultsSuiteName() {
        XCTAssertFalse(DripConstants.userDefaultsSuiteName.isEmpty)
        XCTAssertEqual(DripConstants.userDefaultsSuiteName, "com.drip.app.defaults")
    }

    func testDefaultAlertThresholds() {
        let thresholds = DripConstants.defaultAlertThresholds
        XCTAssertEqual(thresholds.count, 3)
        // All thresholds should be between 0 and 1
        for threshold in thresholds {
            XCTAssertGreaterThan(threshold, 0.0)
            XCTAssertLessThanOrEqual(threshold, 1.0)
        }
        // Should be sorted ascending
        XCTAssertEqual(thresholds, thresholds.sorted())
        XCTAssertEqual(thresholds, [0.5, 0.75, 0.9])
    }
}
