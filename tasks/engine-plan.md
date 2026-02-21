# Network Engine Plan — Sources/DripEngine/

## Architecture

Protocol-based dependency injection for all system interfaces (CoreWLAN, getifaddrs, UNUserNotificationCenter) so tests use mocks. Each component has a single responsibility.

### Protocols (for testability)
- `WiFiClientProtocol` — wraps CWWiFiClient (SSID, BSSID, interface name)
- `NetworkInterfaceProvider` — wraps getifaddrs() to return interface byte stats
- `NotificationScheduler` — wraps UNUserNotificationCenter

### Dependency Graph
```
ProfileManager --> UsageStore
AlertManager --> ProfileManager
DataTracker --> NetworkInterfaceProvider, UsageStore, AlertManager, ProfileManager
HotspotDetector --> WiFiClientProtocol, DataTracker, ProfileManager
DripEngine (facade) --> all of the above
```

## Implementation Order

### 1. UsageStore.swift
- UserDefaults-backed (DripConstants.userDefaultsSuiteName)
- Thread-safe via serial DispatchQueue
- Methods: saveProfiles/loadProfiles, saveSessions/loadSessions, clearHistory

### 2. ProfileManager.swift
- ObservableObject with @Published profiles
- Auto-create profile from hotspot name (default 10GB limit)
- Reset cycle logic (daily/weekly/monthly/manual)
- Check resets on init and periodically

### 3. AlertManager.swift
- NotificationScheduler protocol for testability
- Track fired thresholds per profile (dedup within cycle)
- Fire at 50%, 75%, 90%, 100%
- Notification content includes usage details

### 4. DataTracker.swift
- NetworkInterfaceProvider protocol returning [(name, bytesIn, bytesOut)]
- SystemNetworkInterfaceProvider using getifaddrs() / if_data
- Timer polling at 2s, baseline counters, delta computation
- Handle counter rollover (UInt32.max)
- Publish via Combine

### 5. HotspotDetector.swift
- WiFiClientProtocol wrapping CWWiFiClient
- Detect WiFi hotspot (SSID patterns like "iPhone", BSSID)
- Detect USB tethering (bridge/RNDIS interfaces)
- Detect Bluetooth PAN (bnep/pan interfaces)
- NWPathMonitor fallback
- Post custom Notification.Name on connect/disconnect

### 6. DripEngine.swift — Replace placeholder with facade
- Wire all components, expose start/stop/state

### 7. Tests (Tests/DripEngineTests/)
- Mock implementations for all protocols
- UsageStore roundtrip, ProfileManager reset logic, AlertManager dedup
- DataTracker byte counting + rollover, HotspotDetector identification
- Target: swift test passes with 0 failures

## Key Decisions
- Protocols over singletons for testability
- Serial DispatchQueues for thread safety (macOS 13 compat, no actors)
- Combine for reactive updates (matches existing ObservableObject models)
- UserDefaults for storage
