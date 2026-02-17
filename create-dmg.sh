#!/bin/bash
set -e

# QFlasher DMG Creation Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="QFlasher"
DMG_NAME="QFlasher"
BUILD_DIR="$SCRIPT_DIR/build"
APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
DMG_PATH="$SCRIPT_DIR/$DMG_NAME.dmg"

echo "📦 QFlasher DMG Creator"
echo "======================"

# Check for create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo "📦 Installing create-dmg via Homebrew..."
    brew install create-dmg
fi

# Build the app
echo "🏗️  Building release version..."
xcodebuild -scheme QFlasher \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Build failed - app not found at $APP_PATH"
    exit 1
fi

echo "✓ Build successful"

# Remove old DMG if exists
rm -f "$DMG_PATH"

# Create DMG
echo "💿 Creating DMG..."
create-dmg \
    --volname "$DMG_NAME" \
    --volicon "$APP_PATH/Contents/Resources/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 150 185 \
    --app-drop-link 450 185 \
    --hide-extension "$APP_NAME.app" \
    "$DMG_PATH" \
    "$APP_PATH" \
    || true  # create-dmg returns non-zero even on success sometimes

if [ -f "$DMG_PATH" ]; then
    echo ""
    echo "✅ DMG created successfully!"
    echo "   Location: $DMG_PATH"
    echo ""
    echo "To distribute:"
    echo "  - For personal use: Share the DMG directly"
    echo "  - For wider distribution: Sign with 'codesign' and notarize with 'xcrun notarytool'"
else
    echo "❌ DMG creation failed"
    exit 1
fi
