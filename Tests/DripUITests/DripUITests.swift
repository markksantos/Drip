import XCTest
@testable import DripUI
@testable import Drip

final class DripUITests: XCTestCase {

    // MARK: - Version

    func testUIVersion() {
        XCTAssertFalse(DripUI.version.isEmpty)
    }

    // MARK: - FillLevel

    func testFillLevelZero() {
        let ratio = FillLevel.ratio(used: 0, limit: 10_737_418_240)
        XCTAssertEqual(ratio, 0.0, accuracy: 0.001)
    }

    func testFillLevel25Percent() {
        let limit: Int64 = 10_737_418_240
        let used = limit / 4
        let ratio = FillLevel.ratio(used: used, limit: limit)
        XCTAssertEqual(ratio, 0.25, accuracy: 0.001)
    }

    func testFillLevel50Percent() {
        let limit: Int64 = 10_737_418_240
        let used = limit / 2
        let ratio = FillLevel.ratio(used: used, limit: limit)
        XCTAssertEqual(ratio, 0.5, accuracy: 0.001)
    }

    func testFillLevel75Percent() {
        let limit: Int64 = 10_737_418_240
        let used = Int64(Double(limit) * 0.75)
        let ratio = FillLevel.ratio(used: used, limit: limit)
        XCTAssertEqual(ratio, 0.75, accuracy: 0.001)
    }

    func testFillLevel100Percent() {
        let limit: Int64 = 10_737_418_240
        let ratio = FillLevel.ratio(used: limit, limit: limit)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.001)
    }

    func testFillLevelCapsAtOne() {
        let limit: Int64 = 10_737_418_240
        let ratio = FillLevel.ratio(used: limit * 2, limit: limit)
        XCTAssertEqual(ratio, 1.0, accuracy: 0.001)
    }

    func testFillLevelUnlimitedReturnsZero() {
        let ratio = FillLevel.ratio(used: 5_000_000_000, limit: nil)
        XCTAssertEqual(ratio, 0.0)
    }

    func testFillLevelZeroLimitReturnsZero() {
        let ratio = FillLevel.ratio(used: 1000, limit: 0)
        XCTAssertEqual(ratio, 0.0)
    }

    // MARK: - UsageLevel (color thresholds)

    func testUsageLevelNormal() {
        XCTAssertEqual(UsageLevel.from(ratio: 0.0), .normal)
        XCTAssertEqual(UsageLevel.from(ratio: 0.5), .normal)
        XCTAssertEqual(UsageLevel.from(ratio: 0.74), .normal)
        XCTAssertEqual(UsageLevel.from(ratio: 0.75), .normal)
    }

    func testUsageLevelWarning() {
        XCTAssertEqual(UsageLevel.from(ratio: 0.76), .warning)
        XCTAssertEqual(UsageLevel.from(ratio: 0.8), .warning)
        XCTAssertEqual(UsageLevel.from(ratio: 0.9), .warning)
    }

    func testUsageLevelCritical() {
        XCTAssertEqual(UsageLevel.from(ratio: 0.91), .critical)
        XCTAssertEqual(UsageLevel.from(ratio: 0.95), .critical)
        XCTAssertEqual(UsageLevel.from(ratio: 1.0), .critical)
    }

    // MARK: - ByteFormatter

    func testByteFormatterZero() {
        let result = ByteFormatter.string(from: 0)
        XCTAssertTrue(result.contains("0") || result.contains("Zero"))
    }

    func testByteFormatterGigabytes() {
        // 1 GB in binary = 1,073,741,824 bytes
        let result = ByteFormatter.string(from: 1_073_741_824)
        XCTAssertTrue(result.contains("GB") || result.contains("1"))
    }

    func testByteFormatterMegabytes() {
        // 500 MB
        let result = ByteFormatter.string(from: 524_288_000)
        XCTAssertTrue(result.contains("MB") || result.contains("500"))
    }

    func testUsageStringGBOnly() {
        let result = ByteFormatter.usageString(
            used: 4_294_967_296, // ~4 GB
            limit: 10_737_418_240, // 10 GB
            format: .gbOnly
        )
        XCTAssertTrue(result.contains("/"), "Expected '/' separator in gbOnly format: \(result)")
        XCTAssertFalse(result.contains("%"), "gbOnly should not contain %: \(result)")
    }

    func testUsageStringGBAndPercent() {
        let result = ByteFormatter.usageString(
            used: 5_368_709_120, // 5 GB
            limit: 10_737_418_240, // 10 GB
            format: .gbAndPercent
        )
        XCTAssertTrue(result.contains("/"), "Expected '/' separator: \(result)")
        XCTAssertTrue(result.contains("%"), "Expected percent in gbAndPercent format: \(result)")
    }

    func testUsageStringPercentOnly() {
        let result = ByteFormatter.usageString(
            used: 5_368_709_120, // 5 GB
            limit: 10_737_418_240, // 10 GB
            format: .percentOnly
        )
        XCTAssertTrue(result.contains("%"), "Expected percent: \(result)")
        XCTAssertFalse(result.contains("/"), "percentOnly should not contain '/': \(result)")
    }

    func testUsageStringUnlimited() {
        let result = ByteFormatter.usageString(
            used: 5_368_709_120,
            limit: nil,
            format: .gbOnly
        )
        XCTAssertFalse(result.contains("/"), "Unlimited should not have separator: \(result)")
    }

    // MARK: - DripViewModel: Profile CRUD

    func testAddProfile() {
        let vm = DripViewModel()
        XCTAssertEqual(vm.profiles.count, 0)

        let profile = HotspotProfile(name: "Test", dataLimitBytes: 10_737_418_240)
        vm.addProfile(profile)
        XCTAssertEqual(vm.profiles.count, 1)
        XCTAssertEqual(vm.profiles.first?.name, "Test")
    }

    func testDeleteProfile() {
        let vm = DripViewModel()
        let profile = HotspotProfile(name: "Test", dataLimitBytes: 10_737_418_240)
        vm.addProfile(profile)
        XCTAssertEqual(vm.profiles.count, 1)

        vm.deleteProfile(profile)
        XCTAssertEqual(vm.profiles.count, 0)
    }

    func testDeleteActiveProfileSwitchesToFirst() {
        let vm = DripViewModel()
        let p1 = HotspotProfile(name: "Profile 1", dataLimitBytes: 10_737_418_240)
        let p2 = HotspotProfile(name: "Profile 2", dataLimitBytes: 5_368_709_120)
        vm.addProfile(p1)
        vm.addProfile(p2)
        vm.activeProfile = p2

        vm.deleteProfile(p2)
        XCTAssertEqual(vm.activeProfile?.id, p1.id)
    }

    func testSwitchProfile() {
        let vm = DripViewModel()
        let p1 = HotspotProfile(name: "Profile 1", dataLimitBytes: 10_737_418_240)
        let p2 = HotspotProfile(name: "Profile 2", dataLimitBytes: 5_368_709_120)
        vm.addProfile(p1)
        vm.addProfile(p2)
        vm.activeProfile = p1

        vm.switchProfile(p2)
        XCTAssertEqual(vm.activeProfile?.id, p2.id)
    }

    // MARK: - DripViewModel: Reset Usage

    func testResetUsage() {
        let profile = HotspotProfile(name: "Test", dataLimitBytes: 10_737_418_240, currentUsageBytes: 5_000_000_000)
        let vm = DripViewModel(activeProfile: profile)

        vm.resetUsage()
        XCTAssertEqual(profile.currentUsageBytes, 0)
    }

    // MARK: - DripViewModel: Connection State

    func testIsConnected() {
        let vm = DripViewModel(connectionState: .connected(hotspotName: "iPhone", interfaceName: "en1"))
        XCTAssertTrue(vm.isConnected)
        XCTAssertEqual(vm.connectedHotspotName, "iPhone")
    }

    func testIsDisconnected() {
        let vm = DripViewModel(connectionState: .disconnected)
        XCTAssertFalse(vm.isConnected)
        XCTAssertNil(vm.connectedHotspotName)
    }

    // MARK: - DripViewModel: Session History

    func testClearHistory() {
        let vm = DripViewModel.mock()
        XCTAssertFalse(vm.sessionHistory.isEmpty)

        vm.clearHistory()
        XCTAssertTrue(vm.sessionHistory.isEmpty)
    }

    func testRecentHotspots() {
        let vm = DripViewModel.mockDisconnected()
        let recents = vm.recentHotspots
        XCTAssertEqual(recents.count, 2)
        // Most recent should be first
        XCTAssertEqual(recents[0].name, "iPhone Hotspot")
        XCTAssertEqual(recents[1].name, "Galaxy S24")
    }

    func testRecentHotspotsDeduplicates() {
        let profileId = UUID()
        let s1 = UsageSession(profileId: profileId, hotspotName: "iPhone",
                              startDate: Date().addingTimeInterval(-3600),
                              endDate: Date().addingTimeInterval(-1800))
        let s2 = UsageSession(profileId: profileId, hotspotName: "iPhone",
                              startDate: Date().addingTimeInterval(-7200),
                              endDate: Date().addingTimeInterval(-5400))
        let vm = DripViewModel(sessionHistory: [s1, s2])
        XCTAssertEqual(vm.recentHotspots.count, 1)
    }

    // MARK: - DripViewModel: Display Format

    func testDisplayFormatSwitching() {
        let profile = HotspotProfile(
            name: "Test",
            dataLimitBytes: 10_737_418_240,
            currentUsageBytes: 5_368_709_120
        )
        let vm = DripViewModel(activeProfile: profile, displayFormat: .gbOnly)
        let gbOnly = vm.formattedUsage
        XCTAssertFalse(gbOnly.contains("%"))

        vm.displayFormat = .percentOnly
        let pctOnly = vm.formattedUsage
        XCTAssertTrue(pctOnly.contains("%"))
    }

    // MARK: - DripViewModel: Mock Factories

    func testMockFactoryConnected() {
        let vm = DripViewModel.mock()
        XCTAssertTrue(vm.isConnected)
        XCTAssertNotNil(vm.activeProfile)
        XCTAssertNotNil(vm.currentSession)
        XCTAssertFalse(vm.profiles.isEmpty)
    }

    func testMockFactoryDisconnected() {
        let vm = DripViewModel.mockDisconnected()
        XCTAssertFalse(vm.isConnected)
        XCTAssertNil(vm.activeProfile)
        XCTAssertNil(vm.currentSession)
        XCTAssertFalse(vm.sessionHistory.isEmpty)
    }

    // MARK: - Session Duration Formatting

    func testSessionDurationFormatting() {
        let vm = DripViewModel()
        // No session means 0 duration
        XCTAssertEqual(vm.formattedSessionDuration, "0m 00s")
    }
}

