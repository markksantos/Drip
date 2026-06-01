# Distributing Drip

Drip is built with Swift Package Manager. `./bundle.sh` assembles a runnable
`.app`. Getting it onto *other people's* Macs requires an Apple Developer
account and one of the distribution paths below.

## Build matrix

| Mode | Command | Entitlements | Signature | Runs on |
| --- | --- | --- | --- | --- |
| Local dev | `./bundle.sh` | `Drip.dev.entitlements` (network only, no sandbox) | ad-hoc (`-`) | this Mac only |
| Distribution | `SIGN_IDENTITY="Developer ID Application: NAME (TEAMID)" ./bundle.sh` | `Drip.entitlements` (sandbox + wifi-info) | Developer ID + Hardened Runtime | any Mac (after notarization) |

The local build intentionally drops the **App Sandbox** and the restricted
**`com.apple.developer.networking.wifi-info`** entitlement: an ad-hoc signature
cannot satisfy either, so a sandboxed/wifi-info ad-hoc build is killed by AMFI on
launch (exit 137 / launchd error 163). Without `wifi-info`, Drip still tracks
data; it just falls back to the name "iPhone Hotspot" instead of reading the SSID.

## Prerequisites for any real distribution

- An **Apple Developer Program** membership ($99/yr). *(NEEDS FROM MARK)*
- A **Developer ID Application** certificate (DMG / direct download), or an
  **Apple Distribution** certificate (Mac App Store).
- The `wifi-info` entitlement must be enabled for the App ID in the developer
  portal, or the SSID name feature won't work in the signed build.

## Path A — Direct download (DMG), notarized

Best for shipping from the landing page without App Store review.

```bash
# 1. Build + sign with your Developer ID.
SIGN_IDENTITY="Developer ID Application: Mark Santos (TEAMID)" ./bundle.sh

# 2. Package into a DMG.
hdiutil create -volname Drip -srcfolder .build/release/Drip.app \
  -ov -format UDZO Drip.dmg

# 3. Notarize (requires an app-specific password or notarytool keychain profile).
xcrun notarytool submit Drip.dmg \
  --keychain-profile "AC_NOTARY" --wait

# 4. Staple the ticket so it validates offline.
xcrun stapler staple Drip.dmg
```

Then upload `Drip.dmg` and point the landing page "Download for macOS" button at it
(`landing/src/components/Pricing.tsx`, currently `href="#"`).

## Path B — Mac App Store

1. Keep the full sandbox entitlements (`Drip.entitlements`) — already present.
2. App Store builds need an `.xcodeproj`/archive flow rather than `swift build`.
   Create a thin Xcode app target that depends on the SPM package and produces
   the archive, or migrate `Sources/DripApp` into an app target.
3. Provide an App Store Connect listing, screenshots, and privacy details
   (Drip collects nothing — "Data Not Collected").
4. Archive in Xcode → validate → upload → submit for review.

> The `Location` usage strings are already in the generated `Info.plist`; the
> Mac App Store reviewer will exercise the location prompt that backs SSID reads.

## Decision needed from Mark

- **Distribution channel:** DMG direct download, TestFlight, or Mac App Store?
  This drives whether a Developer ID cert (DMG) or Apple Distribution cert
  (App Store) is needed, and whether a thin Xcode target is required (App Store).
- **Apple Developer account credentials** to create the certificate and
  notarize / submit.
