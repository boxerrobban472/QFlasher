#!/bin/bash
set -e

# QFlasher Setup Script
# This script sets up the project for development

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 QFlasher Setup"
echo "=================="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "📦 Installing XcodeGen via Homebrew..."
    brew install xcodegen
else
    echo "✓ XcodeGen is installed"
fi

# Copy arduino-flasher-cli to Resources
CLI_SOURCE="$HOME/Downloads/arduino-flasher-cli-0.5.0-darwin-arm64/arduino-flasher-cli"
CLI_DEST="$SCRIPT_DIR/Resources/arduino-flasher-cli"

if [ -f "$CLI_SOURCE" ]; then
    echo "📋 Copying arduino-flasher-cli to Resources..."
    cp "$CLI_SOURCE" "$CLI_DEST"
    chmod +x "$CLI_DEST"
    echo "✓ CLI copied successfully"
else
    echo "⚠️  arduino-flasher-cli not found at: $CLI_SOURCE"
    echo "   Please download it from Arduino and place it in your Downloads folder"
    echo "   Or copy it manually to: $CLI_DEST"
fi

# Generate Xcode project
echo "🏗️  Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Open QFlasher.xcodeproj in Xcode"
echo "  2. Select your development team in Signing & Capabilities"
echo "  3. Build and run (⌘R)"
echo ""
echo "To build from command line:"
echo "  xcodebuild -scheme QFlasher -configuration Debug build"
echo ""
