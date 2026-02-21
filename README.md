# Drip

A macOS menu bar app that tracks your hotspot data usage in real time. Know exactly how much data you've used, set limits, and get alerts before you hit your cap.

## Features

- Real-time hotspot data monitoring (WiFi and USB tethering)
- Configurable data limits and alert thresholds
- Automatic billing cycle resets (daily, weekly, monthly)
- Multi-profile support for different hotspots
- Session history tracking
- Native macOS menu bar integration

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ or Swift 5.9+ for building from source

## Build

```bash
# Build with Swift Package Manager
swift build

# Run tests
swift test

# Or use the setup script
./init.sh
```

You can also open the project in Xcode by double-clicking `Package.swift`.

## Permissions

Drip requires the following entitlements:

- **Network Client** — to monitor network interface byte counters
- **WiFi Info** — to read the current WiFi SSID for hotspot identification

On macOS 14+, reading the WiFi SSID requires Location Services permission. The system will prompt you to grant access on first launch. This is an Apple requirement for any app that reads WiFi network names.

## Architecture

The project is organized as a Swift Package with three modules:

- **Drip** — shared data models and constants
- **DripEngine** — network monitoring, data tracking, alerts, and persistence
- **DripUI** — SwiftUI views for the menu bar, popover, and settings

## License

MIT
