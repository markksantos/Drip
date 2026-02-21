# Drip — Build Plan

## Phase 1: Infrastructure (project-infra)
- [x] Package.swift with 3 targets (DripEngine, DripUI, DripApp)
- [x] Shared models (Models.swift, Constants.swift)
- [x] Info.plist / entitlements
- [x] README.md
- [x] init.sh setup script
- [x] Integration tests

## Phase 2: Network Engine (network-engine)
- [ ] UsageStore.swift — persistent local storage
- [ ] ProfileManager.swift — multi-profile management
- [ ] AlertManager.swift — threshold notifications
- [ ] DataTracker.swift — byte counting via getifaddrs()
- [ ] HotspotDetector.swift — WiFi/USB/BT hotspot detection
- [ ] DripEngine.swift — public facade wiring all components
- [ ] Engine unit tests

## Phase 3: Menu Bar UI (menu-bar-ui)
- [ ] DripApp.swift — MenuBarExtra entry point
- [ ] MenuBarIcon.swift — filling water droplet icon
- [ ] PopoverView.swift — usage display popover
- [ ] SettingsView.swift — settings window with tabs
- [ ] NotConnectedView.swift — disconnected state
- [ ] UI tests

## Phase 4: Integration & Polish (lead)
- [ ] End-to-end test: connect → track → alert
- [ ] Final build verification
- [ ] Git commit
