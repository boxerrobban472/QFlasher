# QFlasher

A macOS app to flash Arduino UNO Q boards with the latest Debian firmware.

## Features
- Automatic USB device detection (Qualcomm EDL mode)
- Step-by-step flashing wizard with visual instructions
- Safe cancellation indicators

## Requirements
- macOS 13.0 (Ventura) or later
- Arduino UNO Q board
- `arduino-flasher-cli` binary (bundled)

## Building
1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate Xcode project: `xcodegen generate`
3. Open `QFlasher.xcodeproj` and build

## Usage
1. Launch QFlasher
2. Click "Flash My Board"
3. Follow the on-screen instructions to connect the jumper
4. Connect your Arduino UNO Q via USB
5. Wait for flashing to complete
6. Remove jumper and reconnect board

## License
MIT
