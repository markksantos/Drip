import XCTest
@testable import Drip

final class ModelsTests: XCTestCase {

    // MARK: - ResetCycle

    func testResetCycleCodableRoundtrip() throws {
        for cycle in ResetCycle.allCases {
            let data = try JSONEncoder().encode(cycle)
            let decoded = try JSONDecoder().decode(ResetCycle.self, from: data)
            XCTAssertEqual(decoded, cycle)
        }
    }

    func testResetCycleAllCases() {
        XCTAssertEqual(ResetCycle.allCases.count, 4)
        XCTAssertTrue(ResetCycle.allCases.contains(.daily))
        XCTAssertTrue(ResetCycle.allCases.contains(.weekly))
        XCTAssertTrue(ResetCycle.allCases.contains(.monthly))
        XCTAssertTrue(ResetCycle.allCases.contains(.manual))
    }

    // MARK: - ConnectionState

    func testConnectionStateDisconnectedCodable() throws {
        let state = ConnectionState.disconnected
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ConnectionState.self, from: data)
        XCTAssertEqual(decoded, state)
    }

    func testConnectionStateConnectedCodable() throws {
        let state = ConnectionState.connected(hotspotName: "iPhone", interfaceName: "en0")
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(ConnectionState.self, from: data)
        XCTAssertEqual(decoded, state)
    }

    // MARK: - HotspotProfile

    func testHotspotProfileCodableRoundtrip() throws {
        let profile = HotspotProfile(
            name: "My iPhone",
            dataLimitBytes: 10_737_418_240,
            alertThresholds: [0.5, 0.75, 0.9],
            resetCycle: .monthly,
            resetDay: 1,
            currentUsageBytes: 5_000_000_000,
            lastResetDate: Date(timeIntervalSince1970: 1700000000)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        let decoded = try JSONDecoder().decode(HotspotProfile.self, from: data)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.name, profile.name)
        XCTAssertEqual(decoded.dataLimitBytes, profile.dataLimitBytes)
        XCTAssertEqual(decoded.alertThresholds, profile.alertThresholds)
        XCTAssertEqual(decoded.resetCycle, profile.resetCycle)
        XCTAssertEqual(decoded.resetDay, profile.resetDay)
        XCTAssertEqual(decoded.currentUsageBytes, profile.currentUsageBytes)
        XCTAssertEqual(decoded.lastResetDate, profile.lastResetDate)
    }

    func testHotspotProfileNilDataLimit() throws {
        let profile = HotspotProfile(
            name: "Unlimited Plan",
            dataLimitBytes: nil,
            resetCycle: .manual
        )

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(HotspotProfile.self, from: data)

        XCTAssertNil(decoded.dataLimitBytes)
        XCTAssertEqual(decoded.name, "Unlimited Plan")
        XCTAssertEqual(decoded.resetCycle, .manual)
    }

    func testHotspotProfileDefaults() {
        let profile = HotspotProfile(name: "Test")
        XCTAssertNil(profile.dataLimitBytes)
        XCTAssertEqual(profile.alertThresholds, [0.5, 0.75, 0.9])
        XCTAssertEqual(profile.resetCycle, .monthly)
        XCTAssertNil(profile.resetDay)
        XCTAssertEqual(profile.currentUsageBytes, 0)
    }

    // MARK: - UsageSession

    func testUsageSessionCodableRoundtrip() throws {
        let profileId = UUID()
        let session = UsageSession(
            profileId: profileId,
            hotspotName: "iPhone",
            startDate: Date(timeIntervalSince1970: 1700000000),
            endDate: Date(timeIntervalSince1970: 1700003600),
            bytesDown: 500_000_000,
            bytesUp: 50_000_000
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(UsageSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.profileId, session.profileId)
        XCTAssertEqual(decoded.hotspotName, session.hotspotName)
        XCTAssertEqual(decoded.startDate, session.startDate)
        XCTAssertEqual(decoded.endDate, session.endDate)
        XCTAssertEqual(decoded.bytesDown, session.bytesDown)
        XCTAssertEqual(decoded.bytesUp, session.bytesUp)
    }

    func testUsageSessionNilEndDate() throws {
        let session = UsageSession(
            profileId: UUID(),
            hotspotName: "Android",
            bytesDown: 1000,
            bytesUp: 500
        )

        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(UsageSession.self, from: data)

        XCTAssertNil(decoded.endDate)
        XCTAssertEqual(decoded.hotspotName, "Android")
    }

    func testUsageSessionDefaults() {
        let profileId = UUID()
        let session = UsageSession(profileId: profileId, hotspotName: "Test")
        XCTAssertNil(session.endDate)
        XCTAssertEqual(session.bytesDown, 0)
        XCTAssertEqual(session.bytesUp, 0)
        XCTAssertEqual(session.profileId, profileId)
    }
}
