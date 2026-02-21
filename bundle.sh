#!/bin/bash
# Creates a proper macOS .app bundle from the swift build output
set -e

APP_NAME="Drip"
BUILD_DIR=".build/debug"
BUNDLE_DIR="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${BUNDLE_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"

# Clean previous bundle
rm -rf "${BUNDLE_DIR}"

# Create bundle structure
mkdir -p "${MACOS}"

# Copy executable
cp "${BUILD_DIR}/DripApp" "${MACOS}/${APP_NAME}"

# Create Info.plist
cat > "${CONTENTS}/Info.plist" << 'PLIST'
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
    <string>0.1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Drip</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSLocationUsageDescription</key>
    <string>Drip needs location permission to identify which WiFi hotspot you are connected to. Your actual location is never read or stored.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Drip needs location permission to identify which WiFi hotspot you are connected to. Your actual location is never read or stored.</string>
</dict>
</plist>
PLIST

echo "Bundle created at ${BUNDLE_DIR}"
