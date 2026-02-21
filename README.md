<div align="center">

# 💧 Drip

**Track hotspot data usage in real time — know before you hit your limit**

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138?style=for-the-badge&logo=swift&logoColor=white)](#)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-007AFF?style=for-the-badge&logo=swift&logoColor=white)](#)
[![macOS](https://img.shields.io/badge/macOS-13%2B_Ventura-000000?style=for-the-badge&logo=apple&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](#)

[Features](#-features) · [Getting Started](#-getting-started) · [Tech Stack](#️-tech-stack)

</div>

---

## ✨ Features

- **Real-Time Monitoring** — Tracks bytes sent and received through your hotspot connection with 2-second polling
- **Hotspot Detection** — Automatically detects iPhone/iPad hotspots via WiFi, USB, or Bluetooth tethering
- **Data Limit Alerts** — Configurable alerts at 50%, 75%, 90%, and 100% of your data cap
- **Billing Cycle Resets** — Automatic usage resets on daily, weekly, monthly, or manual schedules
- **Multi-Profile Support** — Different data limits and settings for each hotspot
- **Session History** — View past sessions with download/upload breakdown
- **Menu Bar Icon** — Water droplet fill indicator shows usage at a glance
- **Launch at Login** — Start automatically with macOS
- **Menu Bar Only** — No dock icon, minimal footprint

## 🚀 Getting Started

### Prerequisites

- macOS 13.0+ (Ventura)
- Swift 5.9+
- Location permission on macOS 14+ (for WiFi SSID identification)

### Installation

```bash
git clone https://github.com/markksantos/Drip.git
cd Drip
./bundle.sh
cp -r .build/debug/Drip.app /Applications/
```

Or build and run directly:

```bash
swift build
open .build/debug/DripApp
```

### Permissions

Drip requires **Network** access to read interface byte counters and **WiFi Info** access to identify hotspot names. On macOS 14+, reading the WiFi SSID also requires **Location Services** — your actual location is never accessed or stored.

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 5.9+ |
| UI | SwiftUI |
| Networking | CoreWLAN, Network framework |
| Data Tracking | Darwin/ifaddrs |
| Notifications | UserNotifications |
| Persistence | UserDefaults |
| Platform | macOS 13+ (Ventura) |

## 📁 Project Structure

```
Drip/
├── Sources/
│   ├── Drip/
│   │   ├── Models.swift               # HotspotProfile, UsageSession, ConnectionState
│   │   └── Constants.swift            # App-wide defaults and identifiers
│   ├── DripEngine/
│   │   ├── DripEngine.swift           # Facade orchestrating all components
│   │   ├── HotspotDetector.swift      # WiFi/USB/Bluetooth hotspot detection
│   │   ├── DataTracker.swift          # Interface byte counting via getifaddrs()
│   │   ├── ProfileManager.swift       # Multi-profile and reset cycle management
│   │   ├── UsageStore.swift           # UserDefaults persistence
│   │   └── AlertManager.swift         # Threshold notification scheduling
│   ├── DripUI/
│   │   ├── ViewModels.swift           # DripViewModel, ByteFormatter, DisplayFormat
│   │   ├── MenuBarIcon.swift          # Water droplet icon with fill level
│   │   ├── PopoverView.swift          # Connected state popover
│   │   ├── SettingsView.swift         # General, Profiles, History, About tabs
│   │   └── NotConnectedView.swift     # Disconnected state display
│   └── DripApp/
│       └── main.swift                 # App entry point with MenuBarExtra
├── Tests/
│   ├── DripEngineTests/
│   │   └── DripEngineTests.swift      # 40 engine tests
│   ├── DripUITests/
│   │   └── DripUITests.swift          # 33 UI/ViewModel tests
│   └── IntegrationTests/
│       ├── ModelsTests.swift          # Model tests
│       └── ConstantsTests.swift       # Constants validation tests
├── bundle.sh                          # Build release .app bundle
├── init.sh                            # Build, test, and open
└── Package.swift
```

## 📄 License

MIT License © 2025 Mark Santos
