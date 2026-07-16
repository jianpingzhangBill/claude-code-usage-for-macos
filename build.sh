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

BIN_DIR="$(swift build -c release --show-bin-path)"
BIN_PATH="$BIN_DIR/$BIN_NAME"

echo "▸ Assembling app bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH" "$APP/Contents/MacOS/$BIN_NAME"

# App icon (if present)
if [ -f "icon/AppIcon.icns" ]; then
    cp "icon/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

# Localized resources: SwiftPM emits <Package>_<Target>.bundle next to the
# binary. Bundle.module finds it under Contents/Resources, so copy it there.
for b in "$BIN_DIR"/*.bundle; do
    [ -e "$b" ] && cp -R "$b" "$APP/Contents/Resources/"
done

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>     <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>      <string>com.local.claudeusagemonitor</string>
    <key>CFBundleExecutable</key>      <string>$BIN_NAME</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>zh-Hans</string>
        <string>ja</string>
        <string>ko</string>
        <string>de</string>
        <string>fr</string>
        <string>pt</string>
        <string>ru</string>
    </array>
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
