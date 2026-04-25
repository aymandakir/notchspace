#!/usr/bin/env bash
# package.sh — Build, sign, notarize, and package NotchSpace as a DMG.
#
# Required env vars (set these in your shell or CI secrets):
#   APPLE_ID            your@apple.id
#   APPLE_TEAM_ID       XXXXXXXXXX
#   NOTARY_PASSWORD     app-specific password (https://appleid.apple.com)
#   SIGNING_IDENTITY    "Developer ID Application: Your Name (XXXXXXXXXX)"
#
# Prerequisites:
#   brew install create-dmg xcpretty

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────

SCHEME="NotchSpace"
CONFIGURATION="Release"
DERIVED_DATA="$(pwd)/.build/DerivedData"
ARCHIVE_PATH="$(pwd)/.build/NotchSpace.xcarchive"
EXPORT_PATH="$(pwd)/.build/export"
APP_PATH="$EXPORT_PATH/NotchSpace.app"
DMG_NAME="NotchSpace"
VERSION=$(defaults read "$(pwd)/Sources/App/Resources/Assets.xcassets/../Info.plist" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")
DMG_PATH="$(pwd)/dist/NotchSpace-${VERSION}.dmg"

echo "▸ Building NotchSpace ${VERSION}"

# ─── Archive ──────────────────────────────────────────────────────────────────

mkdir -p dist

xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -derivedDataPath "$DERIVED_DATA" \
  -destination "generic/platform=macOS" \
  CODE_SIGN_IDENTITY="${SIGNING_IDENTITY:-}" \
  DEVELOPMENT_TEAM="${APPLE_TEAM_ID:-}" \
  | xcpretty

echo "▸ Exporting archive"

# Export the app using Developer ID signing
cat > /tmp/ExportOptions.plist <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist /tmp/ExportOptions.plist \
  | xcpretty

echo "▸ Notarizing"

# Submit for notarization and staple the result
xcrun notarytool submit "$APP_PATH" \
  --apple-id "${APPLE_ID:-}" \
  --team-id "${APPLE_TEAM_ID:-}" \
  --password "${NOTARY_PASSWORD:-}" \
  --wait

xcrun stapler staple "$APP_PATH"

echo "▸ Creating DMG"

create-dmg \
  --volname "$DMG_NAME" \
  --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
  --window-pos 200 120 \
  --window-size 660 400 \
  --icon-size 120 \
  --icon "NotchSpace.app" 180 185 \
  --hide-extension "NotchSpace.app" \
  --app-drop-link 480 185 \
  --background "Scripts/dmg-background.png" \
  --hdiutil-quiet \
  "$DMG_PATH" \
  "$EXPORT_PATH/"

echo "▸ Notarizing DMG"

xcrun notarytool submit "$DMG_PATH" \
  --apple-id "${APPLE_ID:-}" \
  --team-id "${APPLE_TEAM_ID:-}" \
  --password "${NOTARY_PASSWORD:-}" \
  --wait

xcrun stapler staple "$DMG_PATH"

echo ""
echo "✓  $DMG_PATH"
echo "   SHA-256: $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
