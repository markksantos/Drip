import XCTest
import Combine
@testable import Drip
@testable import DripEngine
@testable import DripUI

// MARK: - Mocks
//
// These conform to the public protocols exposed by DripEngine, so the
// integration target can inject deterministic system behaviour and drive
// the full connect → track → alert → disconnect path through the facade.

private final class IntegrationWiFiClient: WiFiClientProtocol {
    var wifiInfo: WiFiInfo?
    func currentWiFiInfo() -> WiFiInfo? { wifiInfo }
}

private final class IntegrationInterfaceProvider: NetworkInterfaceProvider {
    var stats: [InterfaceStats] = []
    func interfaceStats() -> [InterfaceStats] { stats }
}

private final class IntegrationIPDetector: HotspotIPDetector {
    var result: (interfaceName: String, ip: String)?
    func detectHotspotInterface() -> (interfaceName: String, ip: String)? { result }
}

private final class IntegrationNotificationScheduler: NotificationScheduler {
    var scheduled: [(title: String, body: String, identifier: String)] = []
    func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        completionHandler(true, nil)
    }
    func scheduleNotification(title: String, body: String, identifier: String) {
        scheduled.append((title: title, body: body, identifier: identifier))
    }
}

// MARK: - End-to-End Integration Tests

/// Exercises the whole stack through the `DripEngine` facade using mock
/// protocols, then verifies the `DripViewModel` reflects the same state.
final class EndToEndTests: XCTestCase {

    private func makeStore() -> UsageStore {
        let defaults = UserDefaults(suiteName: "com.drip.integration.\(UUID().uuidString)")!
        return UsageStore(defaults: defaults)
    }

    // MARK: connect → track → alert → disconnect

    func testFullConnectTrackAlertDisconnectFlow() {
        let store = makeStore()
        let wifi = IntegrationWiFiClient()
        let provider = IntegrationInterfaceProvider()
        let ipDetector = IntegrationIPDetector()
        let scheduler = IntegrationNotificationScheduler()

        // 1 GB limit so a 600 MB burst crosses the 50% threshold.
        let limit: Int64 = 1_073_741_824
        provider.stats = [InterfaceStats(name: "en1", bytesIn: 0, bytesOut: 0)]

        let engine = DripEngine(
            store: store,
            wifiClient: wifi,
            interfaceProvider: provider,
            ipDetector: ipDetector,
            notificationScheduler: scheduler
        )

        // Pre-create a profile with a tight limit and known name so the
        // auto-created profile for "iPhone Hotspot" picks up our limit.
        let profile = engine.profileManager.profileForHotspot(named: "iPhone Hotspot")
        profile.dataLimitBytes = limit
        profile.alertThresholds = [0.5]
        engine.profileManager.persist()

        // 1. No hotspot yet → disconnected.
        engine.refreshConnection()
        XCTAssertEqual(engine.hotspotDetector.connectionState, .disconnected)

        // 2. Hotspot appears (IP-range detection). The detector updates its
        //    own state synchronously; the engine mirrors it on the main queue.
        ipDetector.result = (interfaceName: "en1", ip: "172.20.10.4")
        engine.refreshConnection()

        guard case let .connected(name, iface) = engine.hotspotDetector.connectionState else {
            return XCTFail("Engine should be connected after hotspot appears")
        }
        XCTAssertEqual(name, "iPhone Hotspot")
        XCTAssertEqual(iface, "en1")
        XCTAssertEqual(engine.dataTracker.activeInterface, "en1")

        // The facade's published state catches up after a run-loop tick.
        pumpMainRunLoop()
        XCTAssertEqual(engine.connectionState, .connected(hotspotName: "iPhone Hotspot", interfaceName: "en1"))

        // 3. Simulate 600 MB of download traffic, then poke the tracker.
        provider.stats = [InterfaceStats(name: "en1", bytesIn: 600_000_000, bytesOut: 0)]
        pollTracker(engine.dataTracker)

        XCTAssertEqual(engine.dataTracker.sessionBytesDown, 600_000_000)
        XCTAssertEqual(profile.currentUsageBytes, 600_000_000)

        // 4. The 50% alert should have fired exactly once.
        XCTAssertEqual(scheduler.scheduled.count, 1)
        XCTAssertTrue(scheduler.scheduled[0].title.contains("iPhone Hotspot"))

        // 5. Disconnect → session persisted with an end date.
        ipDetector.result = nil
        engine.refreshConnection()
        XCTAssertEqual(engine.hotspotDetector.connectionState, .disconnected)

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.endDate)
        XCTAssertEqual(sessions.first?.bytesDown, 600_000_000)
    }

    // MARK: usage survives an engine restart

    func testUsagePersistsAcrossEngineRestart() {
        let store = makeStore()

        // First engine: accrue some usage on a profile.
        let engine1 = DripEngine(store: store, notificationScheduler: IntegrationNotificationScheduler())
        let profile = engine1.profileManager.profileForHotspot(named: "Mark's iPhone")
        profile.currentUsageBytes = 4_200_000_000
        engine1.profileManager.persist()

        // Second engine (same store) should see the persisted usage.
        let engine2 = DripEngine(store: store, notificationScheduler: IntegrationNotificationScheduler())
        let reloaded = engine2.profileManager.profile(withId: profile.id)
        XCTAssertNotNil(reloaded)
        XCTAssertEqual(reloaded?.currentUsageBytes, 4_200_000_000)
        XCTAssertEqual(reloaded?.name, "Mark's iPhone")
    }

    // MARK: facade state propagates to the view model contract

    func testViewModelReflectsEngineUsage() {
        let store = makeStore()
        let profile = HotspotProfile(
            name: "iPhone Hotspot",
            dataLimitBytes: 10_737_418_240,
            currentUsageBytes: 5_368_709_120
        )

        // The view model is the UI's source of truth; verify the computed
        // contract the menu bar relies on, fed by engine-shaped data.
        let vm = DripViewModel(
            connectionState: .connected(hotspotName: "iPhone Hotspot", interfaceName: "en1"),
            activeProfile: profile,
            profiles: [profile]
        )

        XCTAssertTrue(vm.isConnected)
        XCTAssertEqual(vm.connectedHotspotName, "iPhone Hotspot")
        XCTAssertEqual(vm.usageRatio, 0.5, accuracy: 0.001)
        XCTAssertEqual(vm.usageLevel, .normal)
    }

    // MARK: switching hotspots opens a new session

    func testSwitchingHotspotsFinalizesPreviousSession() {
        let store = makeStore()
        let provider = IntegrationInterfaceProvider()
        let ipDetector = IntegrationIPDetector()

        provider.stats = [
            InterfaceStats(name: "en1", bytesIn: 0, bytesOut: 0),
            InterfaceStats(name: "bnep0", bytesIn: 0, bytesOut: 0)
        ]

        let engine = DripEngine(
            store: store,
            interfaceProvider: provider,
            ipDetector: ipDetector,
            notificationScheduler: IntegrationNotificationScheduler()
        )

        // Connect via WiFi hotspot.
        ipDetector.result = (interfaceName: "en1", ip: "172.20.10.2")
        engine.refreshConnection()
        XCTAssertEqual(engine.dataTracker.activeInterface, "en1")

        // Switch to a Bluetooth PAN interface (IP detection drops out).
        ipDetector.result = nil
        provider.stats = [InterfaceStats(name: "bnep0", bytesIn: 0, bytesOut: 0)]
        engine.refreshConnection()

        guard case let .connected(name, iface) = engine.hotspotDetector.connectionState else {
            return XCTFail("Should reconnect via Bluetooth PAN")
        }
        XCTAssertEqual(name, "Bluetooth Tethering")
        XCTAssertEqual(iface, "bnep0")

        // The first session was finalized and saved on the switch.
        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.hotspotName, "en1")
        XCTAssertNotNil(sessions.first?.endDate)
    }

    // MARK: - Helpers

    /// Drive a single poll cycle deterministically. In production the tracker
    /// polls on a 2s timer; the internal `pollForTesting()` hook runs one cycle
    /// immediately so tests do not depend on wall-clock timing.
    private func pollTracker(_ tracker: DataTracker) {
        tracker.pollForTesting()
    }

    /// Run the main run loop briefly so Combine sinks that hop to the main
    /// queue (e.g. the facade's `connectionState` mirror) deliver their values.
    private func pumpMainRunLoop() {
        let expectation = expectation(description: "main run loop tick")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }
}
