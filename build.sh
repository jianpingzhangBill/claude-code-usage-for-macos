#!/bin/bash
# Build ClaudeUsageMonitor and package it into a proper macOS .app bundle
# that runs as a menu-bar accessory (no Dock icon).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="Claude Usage Monitor"
BIN_NAME="ClaudeUsageMonitor"
DIST="dist"
APP="$DIST/$APP_NAME.app"

echo "▸ Compiling (release)…"
swift build -c release

BIN_PATH="$(swift build -c release --show-bin-path)/$BIN_NAME"

echo "▸ Assembling app bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH" "$APP/Contents/MacOS/$BIN_NAME"

# App icon (if present)
if [ -f "icon/AppIcon.icns" ]; then
    cp "icon/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>com.local.claudeusagemonitor</string>
    <key>CFBundleExecutable</key>      <string>$BIN_NAME</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundleIconName</key>        <string>AppIcon</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>            <true/>
    <key>NSHighResolutionCapable</key> <true/>
</dict>
</plist>
PLIST

# Ad-hoc code signature so macOS lets it launch locally.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "✓ Built: $APP"
echo "  Launch with:  open \"$APP\""
