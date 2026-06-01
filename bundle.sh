#!/bin/bash
# Build Drip and assemble a macOS .app bundle.
#
# Usage:
#   ./bundle.sh                  # release build, ad-hoc signed (no Apple account)
#   CONFIG=debug ./bundle.sh     # debug build instead of release
#   SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./bundle.sh
#                                # sign with a real Developer ID (for distribution)
#
# The ad-hoc signed bundle runs locally. A Developer ID signature (plus
# notarization — see DISTRIBUTION.md) is required before shipping to other Macs.
set -euo pipefail

APP_NAME="Drip"
CONFIG="${CONFIG:-release}"
BUILD_DIR=".build/${CONFIG}"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"
ENTITLEMENTS="Drip.entitlements"
VERSION="0.1.0"

echo "==> Building DripApp (${CONFIG})..."
swift build -c "${CONFIG}" --product DripApp

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

# Copy executable
cp "${BUILD_DIR}/DripApp" "${MACOS}/${APP_NAME}"

# Copy the app icon if one has been generated.
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${RESOURCES}/AppIcon.icns"
    ICON_PLIST_KEY='<key>CFBundleIconFile</key><string>AppIcon</string>'
else
    ICON_PLIST_KEY=''
fi

# Create Info.plist
cat > "${CONTENTS}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Drip</string>
    <key>CFBundleDisplayName</key>
    <string>Drip</string>
    <key>CFBundleIdentifier</key>
    <string>com.drip.app</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Drip</string>
    ${ICON_PLIST_KEY}
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSLocationUsageDescription</key>
    <string>Drip needs location permission to read the name of the WiFi hotspot you are connected to. Your location is never read or stored.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Drip needs location permission to read the name of the WiFi hotspot you are connected to. Your location is never read or stored.</string>
</dict>
</plist>
PLIST

# Code-sign with entitlements.
#   - Ad-hoc ("-") signature works on the build machine, no Apple account needed,
#     but CANNOT satisfy the App Sandbox — so ad-hoc builds use the sandbox-free
#     Drip.dev.entitlements and stay runnable locally.
#   - A "Developer ID Application" identity (via SIGN_IDENTITY) is required to
#     distribute to other Macs; that path uses the full sandboxed entitlements
#     (Drip.entitlements). Follow up with notarization (see DISTRIBUTION.md).
IDENTITY="${SIGN_IDENTITY:--}"
if [ "${IDENTITY}" = "-" ]; then
    # Local dev: sandbox-free entitlements, no Hardened Runtime (an ad-hoc
    # signature + Hardened Runtime is killed by AMFI on launch).
    SIGN_ENTITLEMENTS="Drip.dev.entitlements"
    RUNTIME_FLAG=""
else
    # Distribution: full sandboxed entitlements + Hardened Runtime (required
    # for notarization).
    SIGN_ENTITLEMENTS="${ENTITLEMENTS}"
    RUNTIME_FLAG="--options=runtime"
fi
echo "==> Code-signing with identity: ${IDENTITY} (entitlements: ${SIGN_ENTITLEMENTS})"
codesign --force ${RUNTIME_FLAG:+$RUNTIME_FLAG} \
    --entitlements "${SIGN_ENTITLEMENTS}" \
    --sign "${IDENTITY}" \
    "${BUNDLE_DIR}"

echo "==> Verifying signature..."
codesign --verify --verbose "${BUNDLE_DIR}"

echo ""
echo "Bundle created at ${BUNDLE_DIR}"
if [ "${IDENTITY}" = "-" ]; then
    echo "(ad-hoc signed — runs on this Mac; not distributable. See DISTRIBUTION.md.)"
fi
