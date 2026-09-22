#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

echo "==> Building Overnode for macOS (Apple Silicon)..."
swift build -c release

APP_NAME="Overnode"
BUNDLE_DIR="$DIR/build/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating Application Bundle: $BUNDLE_DIR"
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"

# Copy resources
if [ -d ".build/release/Overnode_Overnode.bundle" ]; then
    cp -r ".build/release/Overnode_Overnode.bundle" "$RESOURCES_DIR/"
fi

# Create Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>fr</string>
    <key>CFBundleExecutable</key>
    <string>Overnode</string>
    <key>CFBundleIdentifier</key>
    <string>fr.overnode.OvernodeApp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Overnode</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>fr.overnode.auth</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>overnode</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Clear extended attributes before signing
xattr -cr "$BUNDLE_DIR"

# Code sign bundle locally with entitlements
if [ -f "$DIR/Overnode.entitlements" ]; then
    codesign --force --deep --sign - --entitlements "$DIR/Overnode.entitlements" "$BUNDLE_DIR"
else
    codesign --force --deep --sign - "$BUNDLE_DIR"
fi

echo "==> Overnode.app successfully created at $BUNDLE_DIR"
