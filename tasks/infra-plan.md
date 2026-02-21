# Infrastructure Plan — Task #1

## Files to create (in order):

1. **Package.swift** — SPM manifest with 4 targets:
   - `Drip` (library) — shared models in Sources/Drip/
   - `DripEngine` (library) — depends on `Drip`
   - `DripUI` (library) — depends on `Drip`, `DripEngine`
   - `DripApp` (executableTarget) — depends on `DripEngine`, `DripUI`
   - Platform: .macOS(.v13)
   - No external dependencies

2. **Sources/Drip/Models.swift** — Shared data models:
   - `ResetCycle` enum: daily, weekly, monthly, manual — Codable, CaseIterable
   - `ConnectionState` enum: disconnected, connected(hotspotName, interfaceName) — Codable
   - `HotspotProfile` class: ObservableObject with @Published properties, Codable, Identifiable
   - `UsageSession` class: ObservableObject with @Published properties, Codable, Identifiable
   - Manual Codable conformance for ObservableObject classes (CodingKeys + init(from:) + encode(to:))

3. **Sources/Drip/Constants.swift** — Static constants:
   - defaultDataLimitBytes = 10_737_418_240
   - pollingInterval = 2.0
   - minimumMacOSVersion = 13.0
   - bundleIdentifier = "com.drip.app"
   - userDefaultsSuiteName = "com.drip.app.defaults"
   - defaultAlertThresholds = [0.5, 0.75, 0.9]

4. **Sources/DripEngine/DripEngine.swift** — Placeholder export file (so target compiles)
5. **Sources/DripUI/DripUI.swift** — Placeholder export file (so target compiles)
6. **Sources/DripApp/main.swift** — Minimal SwiftUI app entry point (MenuBarExtra placeholder)

7. **Drip.entitlements** — Sandbox + network + wifi-info entitlements

8. **README.md** — Description, build instructions, permissions

9. **init.sh** — Build + test + open script (chmod +x)

10. **Tests/IntegrationTests/ModelsTests.swift** — Codable roundtrip tests for all models
11. **Tests/IntegrationTests/ConstantsTests.swift** — Constants validation tests

## Key decisions:
- Use ObservableObject + @Published (not @Observable) for macOS 13 compat
- HotspotProfile and UsageSession as classes (required for ObservableObject)
- ConnectionState and ResetCycle as enums (simple value types)
- Manual Codable for classes with @Published
- Placeholder files in DripEngine/DripUI so SPM resolves cleanly
- DripApp uses @main with SwiftUI App protocol
