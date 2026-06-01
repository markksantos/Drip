# Drip — Overnight Worklog

## What it is

Drip is a native macOS menu bar app that tracks iPhone-hotspot data usage in
real time. It lives in the menu bar as a water-droplet icon that fills as you
consume data, fires macOS notifications before you hit your cap, supports
multiple hotspot profiles with daily/weekly/monthly/manual billing-cycle
resets, and keeps session history. Everything is local — no cloud, no account.

Stack: Swift 5.9, SwiftUI `MenuBarExtra`, Swift Package Manager, CoreWLAN,
Combine, `UserDefaults`, macOS 13+. A Next.js static-export marketing landing
page lives in `landing/`.

## Starting state (honest completeness: ~80%)

The triage hint said 72%, but the code was further along than that. This is a
genuinely well-architected, Mark-authored project (one initial commit, built by
three of his subagents). On arrival:

- `swift build` passed, `swift test` was green at 90 tests.
- The engine (`HotspotDetector`, `DataTracker`, `AlertManager`, `ProfileManager`,
  `UsageStore`, `DripEngine` facade) was complete with protocol-based DI and
  good unit coverage. Every system boundary (CoreWLAN, `getifaddrs`,
  `UNUserNotificationCenter`) was mockable.
- The UI (`MenuBarIconView`, `PopoverView`, `NotConnectedView`, `SettingsView`,
  `DripViewModel`) was complete and wired to the engine via `.live()`.
- The landing page was content-complete and built to a static export.

Real gaps versus a shippable product:

1. **No real end-to-end integration test.** The `IntegrationTests` target only
   held model/constants unit tests — not the connect→track→alert flow the
   finish-list asked for. And the `DripEngine` facade couldn't inject a mock
   `HotspotIPDetector`, so the primary (IP-range) detection path was untestable
   through the facade.
2. **No release/signing path.** `bundle.sh` produced a debug, unsigned bundle
   with no entitlements applied — not runnable as a proper signed app, and the
   `Drip.entitlements` file was never wired into the build.
3. **Menu bar icon had no fill level.** It showed a flat-colored `drop.fill`,
   not the "fills as data is used" droplet the whole product is named for.
4. No `LICENSE` (README claimed MIT), no distribution checklist, no CI.

## What I changed, fixed, added, built

### Engine: testable facade + integration tests
- `Sources/DripEngine/DripEngine.swift` — `init` now accepts an injectable
  `HotspotIPDetector`, and shares one `NetworkInterfaceProvider` between the
  tracker and detector so the full IP-detection path is exercisable with mocks.
  Added `refreshConnection()` to trigger detection on demand.
- `Sources/DripEngine/DataTracker.swift` — added an internal `pollForTesting()`
  hook so a single poll cycle can run deterministically (production polls on a
  2s timer).
- `Tests/IntegrationTests/EndToEndTests.swift` (new) — drives the whole stack
  through the facade with mock protocols: full connect → track 600 MB →
  cross-50%-threshold alert → disconnect-with-session-persisted; hotspot
  switching (WiFi → Bluetooth PAN, finalizing the prior session); usage
  surviving an engine restart; and the view-model state contract. Together with
  the engine-facade wiring this took the suite to **96 tests, all green.**

### UI: the signature filling droplet
- `Sources/DripUI/MenuBarIcon.swift` — new `FillingDropletIcon` renders a faint
  droplet outline with a colored fill that rises from the bottom to the usage
  ratio and animates (`easeInOut`, 0.4s). Color still grades blue → yellow → red
  at the 75% / 90% thresholds. Wired into `MenuBarIconView`; added previews.

### UI: Launch at Login actually works now
- The "Launch at Login" toggle was previously dead — a published bool bound to
  nothing. `Sources/DripUI/LoginItemManager.swift` (new) implements it via
  `SMAppService.mainApp` (macOS 13+) behind a `LoginItemManaging` protocol, and
  `DripViewModel` registers/unregisters the login item when the toggle changes,
  syncing the toggle to the real system state on launch. Guarded so unbundled
  runs / tests degrade to a no-op instead of throwing. Two new tests cover the
  enable/disable path and system-rejection snap-back.

### Packaging / signing / distribution
- `bundle.sh` rewritten — release build by default, generates `Info.plist`
  (LSUIElement agent, location usage strings), copies an app icon if present,
  and code-signs **with entitlements**. Local ad-hoc builds use a sandbox-free
  `Drip.dev.entitlements`; a real `SIGN_IDENTITY` switches to the full sandboxed
  `Drip.entitlements` + Hardened Runtime. Verifies the signature.
- `Drip.dev.entitlements` (new) — network-client only. An ad-hoc signature
  cannot satisfy the App Sandbox **or** the restricted
  `com.apple.developer.networking.wifi-info` entitlement; including either gets
  the process killed by AMFI on launch (exit 137 / launchd error 163). Dropping
  them locally lets the signed `.app` actually run; the app degrades gracefully
  (falls back to the name "iPhone Hotspot" when it can't read the SSID).
- `DISTRIBUTION.md` (new) — DMG+notarization and Mac App Store checklists, and
  the build matrix; spells out the Apple-account + channel decisions needed.

### Project hygiene
- `LICENSE` (new) — MIT, matching the README claim.
- `.github/workflows/ci.yml` (new) — macOS job (swift build + test + bundle)
  and a Linux job (landing `npm ci` + static build).
- `README.md` — rewritten to match reality: run via `bundle.sh` (not
  `swift run`), the `diagnose.swift` tool, the four targets, the landing page,
  and the real 96-test count.
- `.gitignore` — added node_modules, landing build dirs, `*.app`, `*.dmg`,
  Xcode noise. Confirmed no build artifacts or secrets are tracked.
- `diagnose.swift` / `bundle.sh` made executable. `diagnose.swift` was already
  a fully-working diagnostics tool (the "stub" hint was wrong) — verified it
  prints live CoreWLAN state, interface byte counters, and hotspot-IP heuristic.

## Current state

- **Builds?** Yes. `swift build` and `swift build -c release` both clean —
  **zero warnings, zero errors** from a fresh build.
- **Runs?** Yes. `./bundle.sh` → `open .build/release/Drip.app` launches a
  stable menu bar agent (verified the process stays up and quits cleanly).
- **Tests?** Yes. `swift test` → **96 passed, 0 failures.**
- **Landing?** Builds: `npm run build` produces the static export in
  `landing/out/`.

## How to run it locally

```bash
cd /Users/markksantos/Developer/Drip

# Build + test the package
swift build
swift test          # 96 tests

# Run as a real menu bar app (NOT `swift run` — it needs an app bundle)
./bundle.sh         # release build → ad-hoc-signed .build/release/Drip.app
open .build/release/Drip.app
# Look for the droplet in the menu bar; it appears as a connected (filling)
# icon when you're tethered to an iPhone hotspot.

# Diagnostics if detection misbehaves
./diagnose.swift

# Landing page
cd landing && npm install && npm run dev   # http://localhost:3000
```

## How to deploy

This is a desktop app, not a web service — "deploy" means code-sign, notarize,
and distribute. **Do not run any of this without Mark's Apple credentials.**
Full steps are in `DISTRIBUTION.md`. Summary:

1. Build signed: `SIGN_IDENTITY="Developer ID Application: NAME (TEAMID)" ./bundle.sh`
2. DMG: `hdiutil create -volname Drip -srcfolder .build/release/Drip.app -ov -format UDZO Drip.dmg`
3. Notarize: `xcrun notarytool submit Drip.dmg --keychain-profile AC_NOTARY --wait`
4. Staple: `xcrun stapler staple Drip.dmg`
5. Host the DMG and point the landing "Download for macOS" button at it
   (`landing/src/components/Pricing.tsx`, currently `href="#"`).

The landing page itself (static export) can deploy to Vercel from `landing/`
(`output: "export"`, no env vars, no backend).

## NEEDS FROM MARK

- **Apple Developer account credentials** — required to create a Developer ID
  (or Apple Distribution) certificate, enable the `wifi-info` entitlement on the
  App ID, and notarize. Nothing here is fakeable; the local build deliberately
  works around its absence.
- **Distribution channel decision** — DMG direct download, TestFlight, or Mac
  App Store. App Store additionally needs a thin Xcode app target/archive flow
  (SPM alone can't produce an App Store archive); DMG works straight from
  `bundle.sh`.
- **Real download URL** — once a build is hosted, set it on the Pricing CTA
  (left as `href="#"` rather than a fake link).
- **App icon (optional polish)** — `bundle.sh` will pick up
  `Resources/AppIcon.icns` if present; none ships yet, so the app uses the
  system default. Not blocking.

## Honest completeness now: ~93%

What's done: clean build (no warnings), 96 passing tests including a real
end-to-end suite, a stable runnable signed `.app`, the filling-droplet icon, a
working Launch-at-Login feature, release/signing/distribution tooling and docs,
LICENSE, and CI.

What remains (all gated on Mark / a product decision, not on code):
- Real Developer ID signing + notarization (needs the Apple account).
- Distribution-channel choice; if App Store, a thin Xcode app target for
  archiving.
- Hosting the build and wiring the landing download link.
- Optional polish: ship an `AppIcon.icns` (the bundle script already picks one
  up from `Resources/AppIcon.icns` if present) — the app currently uses the
  system default. Not blocking.
