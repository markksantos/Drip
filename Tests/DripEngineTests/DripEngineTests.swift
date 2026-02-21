import XCTest
@testable import DripEngine
@testable import Drip

// MARK: - Mocks

final class MockWiFiClient: WiFiClientProtocol {
    var wifiInfo: WiFiInfo?
    func currentWiFiInfo() -> WiFiInfo? { wifiInfo }
}

final class MockNetworkInterfaceProvider: NetworkInterfaceProvider {
    var stats: [InterfaceStats] = []
    func interfaceStats() -> [InterfaceStats] { stats }
}

final class MockHotspotIPDetector: HotspotIPDetector {
    var result: (interfaceName: String, ip: String)?
    func detectHotspotInterface() -> (interfaceName: String, ip: String)? { result }
}

final class MockNotificationScheduler: NotificationScheduler {
    var authorizationGranted = true
    var scheduledNotifications: [(title: String, body: String, identifier: String)] = []
    var authorizationRequested = false

    func requestAuthorization(completionHandler: @escaping (Bool, Error?) -> Void) {
        authorizationRequested = true
        completionHandler(authorizationGranted, nil)
    }

    func scheduleNotification(title: String, body: String, identifier: String) {
        scheduledNotifications.append((title: title, body: body, identifier: identifier))
    }
}

// MARK: - UsageStore Tests

final class UsageStoreTests: XCTestCase {

    private func makeStore() -> UsageStore {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        return UsageStore(defaults: defaults)
    }

    func testSaveAndLoadProfiles() {
        let store = makeStore()
        let profile = HotspotProfile(name: "Test iPhone", dataLimitBytes: 5_000_000_000)
        store.saveProfiles([profile])

        let loaded = store.loadProfiles()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.name, "Test iPhone")
        XCTAssertEqual(loaded.first?.dataLimitBytes, 5_000_000_000)
        XCTAssertEqual(loaded.first?.id, profile.id)
    }

    func testSaveAndLoadSessions() {
        let store = makeStore()
        let profileId = UUID()
        let session = UsageSession(
            profileId: profileId,
            hotspotName: "iPhone",
            bytesDown: 1024,
            bytesUp: 512
        )
        store.saveSessions([session])

        let loaded = store.loadSessions()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.profileId, profileId)
        XCTAssertEqual(loaded.first?.bytesDown, 1024)
        XCTAssertEqual(loaded.first?.bytesUp, 512)
    }

    func testClearHistory() {
        let store = makeStore()
        let session = UsageSession(profileId: UUID(), hotspotName: "iPhone")
        store.saveSessions([session])
        XCTAssertEqual(store.loadSessions().count, 1)

        store.clearHistory()
        XCTAssertEqual(store.loadSessions().count, 0)
    }

    func testClearAll() {
        let store = makeStore()
        store.saveProfiles([HotspotProfile(name: "Test")])
        store.saveSessions([UsageSession(profileId: UUID(), hotspotName: "Test")])

        store.clearAll()
        XCTAssertEqual(store.loadProfiles().count, 0)
        XCTAssertEqual(store.loadSessions().count, 0)
    }

    func testEmptyLoadReturnsEmptyArrays() {
        let store = makeStore()
        XCTAssertEqual(store.loadProfiles().count, 0)
        XCTAssertEqual(store.loadSessions().count, 0)
    }

    func testMultipleProfilesPersist() {
        let store = makeStore()
        let p1 = HotspotProfile(name: "iPhone 1", dataLimitBytes: 1_000_000)
        let p2 = HotspotProfile(name: "iPhone 2", dataLimitBytes: 2_000_000)
        store.saveProfiles([p1, p2])

        let loaded = store.loadProfiles()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].name, "iPhone 1")
        XCTAssertEqual(loaded[1].name, "iPhone 2")
    }
}

// MARK: - ProfileManager Tests

final class ProfileManagerTests: XCTestCase {

    private func makeManager() -> (ProfileManager, UsageStore) {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)
        let manager = ProfileManager(store: store)
        return (manager, store)
    }

    func testAutoCreateProfile() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "Mark's iPhone")

        XCTAssertEqual(profile.name, "Mark's iPhone")
        XCTAssertEqual(profile.dataLimitBytes, DripConstants.defaultDataLimitBytes)
        XCTAssertEqual(profile.alertThresholds, DripConstants.defaultAlertThresholds)
        XCTAssertEqual(profile.resetCycle, .monthly)
        XCTAssertEqual(manager.profiles.count, 1)
    }

    func testAutoCreateDoesNotDuplicate() {
        let (manager, _) = makeManager()
        let p1 = manager.profileForHotspot(named: "iPhone")
        let p2 = manager.profileForHotspot(named: "iPhone")

        XCTAssertEqual(p1.id, p2.id)
        XCTAssertEqual(manager.profiles.count, 1)
    }

    func testDeleteProfile() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        XCTAssertEqual(manager.profiles.count, 1)

        manager.deleteProfile(withId: profile.id)
        XCTAssertEqual(manager.profiles.count, 0)
    }

    func testDailyReset() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .daily
        profile.currentUsageBytes = 5000
        profile.lastResetDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        XCTAssertTrue(manager.shouldReset(profile: profile, now: Date()))
    }

    func testDailyNoResetSameDay() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .daily
        profile.lastResetDate = Date()

        XCTAssertFalse(manager.shouldReset(profile: profile, now: Date()))
    }

    func testWeeklyReset() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .weekly
        profile.lastResetDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!

        XCTAssertTrue(manager.shouldReset(profile: profile, now: Date()))
    }

    func testMonthlyReset() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .monthly
        profile.lastResetDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!

        XCTAssertTrue(manager.shouldReset(profile: profile, now: Date()))
    }

    func testManualNeverAutoResets() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .manual
        profile.lastResetDate = Calendar.current.date(byAdding: .year, value: -1, to: Date())!

        XCTAssertFalse(manager.shouldReset(profile: profile, now: Date()))
    }

    func testCheckResetsZerosUsage() {
        let (manager, _) = makeManager()
        let profile = manager.profileForHotspot(named: "iPhone")
        profile.resetCycle = .daily
        profile.currentUsageBytes = 999_999
        profile.lastResetDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!

        manager.checkResets()
        XCTAssertEqual(profile.currentUsageBytes, 0)
    }

    func testProfilePersistence() {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)

        let manager1 = ProfileManager(store: store)
        manager1.profileForHotspot(named: "iPhone")
        manager1.persist()

        let manager2 = ProfileManager(store: store)
        XCTAssertEqual(manager2.profiles.count, 1)
        XCTAssertEqual(manager2.profiles.first?.name, "iPhone")
    }
}

// MARK: - AlertManager Tests

final class AlertManagerTests: XCTestCase {

    func testFiresAlertAtThreshold() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5, 0.75, 0.9]
        )
        profile.currentUsageBytes = 500_000

        alert.checkUsage(for: profile)

        XCTAssertEqual(scheduler.scheduledNotifications.count, 1)
        XCTAssertTrue(scheduler.scheduledNotifications[0].title.contains("iPhone"))
    }

    func testFiresMultipleThresholds() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5, 0.75, 0.9]
        )
        profile.currentUsageBytes = 800_000

        alert.checkUsage(for: profile)

        XCTAssertEqual(scheduler.scheduledNotifications.count, 2)
    }

    func testDoesNotReFire() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5]
        )
        profile.currentUsageBytes = 600_000

        alert.checkUsage(for: profile)
        XCTAssertEqual(scheduler.scheduledNotifications.count, 1)

        alert.checkUsage(for: profile)
        XCTAssertEqual(scheduler.scheduledNotifications.count, 1)
    }

    func testCriticalAlertAt100Percent() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5, 0.75, 0.9]
        )
        profile.currentUsageBytes = 1_100_000

        alert.checkUsage(for: profile)

        let criticalNotifications = scheduler.scheduledNotifications.filter {
            $0.title.contains("Exceeded")
        }
        XCTAssertEqual(criticalNotifications.count, 1)
    }

    func testResetThresholds() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5]
        )
        profile.currentUsageBytes = 600_000

        alert.checkUsage(for: profile)
        XCTAssertEqual(scheduler.scheduledNotifications.count, 1)

        alert.resetThresholds(for: profile.id)
        alert.checkUsage(for: profile)
        XCTAssertEqual(scheduler.scheduledNotifications.count, 2)
    }

    func testNoAlertWithoutLimit() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(name: "iPhone", dataLimitBytes: nil)
        profile.currentUsageBytes = 999_999_999

        alert.checkUsage(for: profile)
        XCTAssertEqual(scheduler.scheduledNotifications.count, 0)
    }

    func testHasThresholdFired() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5]
        )
        profile.currentUsageBytes = 600_000

        XCTAssertFalse(alert.hasThresholdFired(profileId: profile.id, threshold: 0.5))
        alert.checkUsage(for: profile)
        XCTAssertTrue(alert.hasThresholdFired(profileId: profile.id, threshold: 0.5))
    }

    func testRequestsPermission() {
        let scheduler = MockNotificationScheduler()
        let alert = AlertManager(scheduler: scheduler)

        let profile = HotspotProfile(
            name: "iPhone",
            dataLimitBytes: 1_000_000,
            alertThresholds: [0.5]
        )
        profile.currentUsageBytes = 600_000

        alert.checkUsage(for: profile)
        XCTAssertTrue(scheduler.authorizationRequested)
    }
}

// MARK: - DataTracker Tests

final class DataTrackerTests: XCTestCase {

    private func makeTracker(stats: [InterfaceStats] = []) -> (DataTracker, MockNetworkInterfaceProvider, UsageStore, ProfileManager, AlertManager) {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)
        let profileManager = ProfileManager(store: store)
        let alertManager = AlertManager(scheduler: MockNotificationScheduler())
        let provider = MockNetworkInterfaceProvider()
        provider.stats = stats
        let tracker = DataTracker(
            interfaceProvider: provider,
            store: store,
            alertManager: alertManager,
            profileManager: profileManager
        )
        return (tracker, provider, store, profileManager, alertManager)
    }

    func testStartTrackingSetsInterface() {
        let initialStats = [InterfaceStats(name: "en0", bytesIn: 1000, bytesOut: 500)]
        let (tracker, _, _, profileManager, _) = makeTracker(stats: initialStats)
        let profile = profileManager.profileForHotspot(named: "iPhone")

        tracker.startTracking(interfaceName: "en0", profileId: profile.id)

        XCTAssertEqual(tracker.activeInterface, "en0")
        XCTAssertEqual(tracker.sessionBytesDown, 0)
        XCTAssertEqual(tracker.sessionBytesUp, 0)
    }

    func testStopTrackingSavesSession() {
        let initialStats = [InterfaceStats(name: "en0", bytesIn: 1000, bytesOut: 500)]
        let (tracker, _, store, profileManager, _) = makeTracker(stats: initialStats)
        let profile = profileManager.profileForHotspot(named: "iPhone")

        tracker.startTracking(interfaceName: "en0", profileId: profile.id)
        tracker.stopTracking()

        let sessions = store.loadSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertNotNil(sessions.first?.endDate)
    }

    func testSessionTotalBytes() {
        let (tracker, _, _, _, _) = makeTracker()
        XCTAssertEqual(tracker.sessionTotalBytes, 0)
    }

    func testStopWithoutStartIsNoOp() {
        let (tracker, _, store, _, _) = makeTracker()
        tracker.stopTracking()
        XCTAssertEqual(store.loadSessions().count, 0)
    }
}

// MARK: - HotspotDetector Tests

final class HotspotDetectorTests: XCTestCase {

    private func makeDetector(
        wifiInfo: WiFiInfo? = nil,
        interfaceStats: [InterfaceStats] = [],
        hotspotIP: (interfaceName: String, ip: String)? = nil
    ) -> (HotspotDetector, MockWiFiClient, MockNetworkInterfaceProvider, MockHotspotIPDetector) {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)
        let profileManager = ProfileManager(store: store)
        let alertManager = AlertManager(scheduler: MockNotificationScheduler())
        let interfaceProvider = MockNetworkInterfaceProvider()
        interfaceProvider.stats = interfaceStats
        let dataTracker = DataTracker(
            interfaceProvider: interfaceProvider,
            store: store,
            alertManager: alertManager,
            profileManager: profileManager
        )
        let wifiClient = MockWiFiClient()
        wifiClient.wifiInfo = wifiInfo
        let ipDetector = MockHotspotIPDetector()
        ipDetector.result = hotspotIP
        let detector = HotspotDetector(
            wifiClient: wifiClient,
            interfaceProvider: interfaceProvider,
            ipDetector: ipDetector,
            dataTracker: dataTracker,
            profileManager: profileManager
        )
        return (detector, wifiClient, interfaceProvider, ipDetector)
    }

    func testDetectsIPhoneSSID() {
        let (detector, _, _, _) = makeDetector()
        XCTAssertTrue(detector.isHotspotSSID("Mark's iPhone"))
        XCTAssertTrue(detector.isHotspotSSID("iPhone"))
        XCTAssertTrue(detector.isHotspotSSID("My iPad"))
        XCTAssertTrue(detector.isHotspotSSID("John's iPhone 15"))
    }

    func testRejectsNonHotspotSSID() {
        let (detector, _, _, _) = makeDetector()
        XCTAssertFalse(detector.isHotspotSSID("HomeWifi"))
        XCTAssertFalse(detector.isHotspotSSID("Starbucks"))
        XCTAssertFalse(detector.isHotspotSSID("NETGEAR-5G"))
    }

    func testDetectsWiFiHotspotConnection() {
        let wifi = WiFiInfo(ssid: "Mark's iPhone", bssid: "AA:BB:CC:DD:EE:FF", interfaceName: "en0")
        let (detector, _, _, _) = makeDetector(wifiInfo: wifi)

        detector.checkConnection()

        if case let .connected(name, iface) = detector.connectionState {
            XCTAssertEqual(name, "Mark's iPhone")
            XCTAssertEqual(iface, "en0")
        } else {
            XCTFail("Expected connected state")
        }
    }

    func testDetectsDisconnection() {
        let wifi = WiFiInfo(ssid: "Mark's iPhone", bssid: nil, interfaceName: "en0")
        let (detector, wifiClient, _, _) = makeDetector(wifiInfo: wifi)

        detector.checkConnection()
        XCTAssertNotEqual(detector.connectionState, .disconnected)

        wifiClient.wifiInfo = nil
        detector.checkConnection()
        XCTAssertEqual(detector.connectionState, .disconnected)
    }

    func testDetectsHotspotByIPRange() {
        let (detector, _, _, _) = makeDetector(
            hotspotIP: (interfaceName: "en0", ip: "172.20.10.2")
        )

        detector.checkConnection()

        if case let .connected(name, iface) = detector.connectionState {
            XCTAssertEqual(name, "iPhone Hotspot")
            XCTAssertEqual(iface, "en0")
        } else {
            XCTFail("Expected connected via IP range detection")
        }
    }

    func testIPDetectionUsesSSIDWhenAvailable() {
        let wifi = WiFiInfo(ssid: "Mark's iPhone", bssid: nil, interfaceName: "en0")
        let (detector, _, _, _) = makeDetector(
            wifiInfo: wifi,
            hotspotIP: (interfaceName: "en0", ip: "172.20.10.2")
        )

        detector.checkConnection()

        if case let .connected(name, _) = detector.connectionState {
            XCTAssertEqual(name, "Mark's iPhone")
        } else {
            XCTFail("Expected connected with SSID name")
        }
    }

    func testDetectsBluetoothPAN() {
        let stats = [InterfaceStats(name: "bnep0", bytesIn: 100, bytesOut: 50)]
        let (detector, _, _, _) = makeDetector(interfaceStats: stats)

        detector.checkConnection()

        if case let .connected(name, iface) = detector.connectionState {
            XCTAssertEqual(name, "Bluetooth Tethering")
            XCTAssertEqual(iface, "bnep0")
        } else {
            XCTFail("Expected connected via Bluetooth PAN")
        }
    }

    func testPostsConnectedNotification() {
        let wifi = WiFiInfo(ssid: "iPhone", bssid: nil, interfaceName: "en0")
        let (detector, _, _, _) = makeDetector(wifiInfo: wifi)

        let expectation = self.expectation(description: "Notification posted")
        let observer = NotificationCenter.default.addObserver(
            forName: .hotspotConnected,
            object: detector,
            queue: .main
        ) { notification in
            XCTAssertEqual(notification.userInfo?[HotspotNotificationKey.hotspotName] as? String, "iPhone")
            XCTAssertEqual(notification.userInfo?[HotspotNotificationKey.interfaceName] as? String, "en0")
            expectation.fulfill()
        }

        detector.checkConnection()
        waitForExpectations(timeout: 2)
        NotificationCenter.default.removeObserver(observer)
    }

    func testPostsDisconnectedNotification() {
        let wifi = WiFiInfo(ssid: "iPhone", bssid: nil, interfaceName: "en0")
        let (detector, wifiClient, _, _) = makeDetector(wifiInfo: wifi)

        detector.checkConnection()

        let expectation = self.expectation(description: "Disconnect notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .hotspotDisconnected,
            object: detector,
            queue: .main
        ) { notification in
            XCTAssertEqual(notification.userInfo?[HotspotNotificationKey.hotspotName] as? String, "iPhone")
            expectation.fulfill()
        }

        wifiClient.wifiInfo = nil
        detector.checkConnection()
        waitForExpectations(timeout: 2)
        NotificationCenter.default.removeObserver(observer)
    }

    func testDoesNotReFireForSameConnection() {
        let wifi = WiFiInfo(ssid: "iPhone", bssid: nil, interfaceName: "en0")
        let (detector, _, _, _) = makeDetector(wifiInfo: wifi)

        var notificationCount = 0
        let observer = NotificationCenter.default.addObserver(
            forName: .hotspotConnected,
            object: detector,
            queue: .main
        ) { _ in
            notificationCount += 1
        }

        detector.checkConnection()
        detector.checkConnection()
        detector.checkConnection()

        let expectation = self.expectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(notificationCount, 1)
        NotificationCenter.default.removeObserver(observer)
    }
}

// MARK: - DripEngine Facade Tests

final class DripEngineFacadeTests: XCTestCase {

    func testEngineVersion() {
        XCTAssertFalse(DripEngine.version.isEmpty)
        XCTAssertEqual(DripEngine.version, "0.1.0")
    }

    func testEngineInitialState() {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)
        let scheduler = MockNotificationScheduler()

        let engine = DripEngine(
            store: store,
            notificationScheduler: scheduler
        )

        XCTAssertEqual(engine.connectionState, .disconnected)
        XCTAssertEqual(engine.sessionBytesDown, 0)
        XCTAssertEqual(engine.sessionBytesUp, 0)
        XCTAssertEqual(engine.sessionTotalBytes, 0)
    }

    func testEngineLoadsSessions() {
        let defaults = UserDefaults(suiteName: "com.drip.test.\(UUID().uuidString)")!
        let store = UsageStore(defaults: defaults)
        let session = UsageSession(profileId: UUID(), hotspotName: "iPhone", bytesDown: 100)
        store.saveSessions([session])

        let engine = DripEngine(store: store, notificationScheduler: MockNotificationScheduler())
        let sessions = engine.loadSessions()
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.bytesDown, 100)
    }
}
