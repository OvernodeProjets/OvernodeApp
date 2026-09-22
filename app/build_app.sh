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
PLUGINS_DIR="$CONTENTS_DIR/PlugIns"
WIDGET_APPEX="$PLUGINS_DIR/OvernodeWidgetExtension.appex"
WIDGET_CONTENTS="$WIDGET_APPEX/Contents"
WIDGET_MACOS="$WIDGET_CONTENTS/MacOS"

echo "==> Creating Application Bundle: $BUNDLE_DIR"
rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$PLUGINS_DIR"
mkdir -p "$WIDGET_MACOS"

# Copy binary
cp ".build/release/$APP_NAME" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

# Copy Widget Extension binary & bundle
if [ -f ".build/release/OvernodeWidgetExtension" ]; then
    cp ".build/release/OvernodeWidgetExtension" "$WIDGET_MACOS/OvernodeWidgetExtension"
    chmod +x "$WIDGET_MACOS/OvernodeWidgetExtension"
    
    # Create Widget Info.plist
    cp "$DIR/widget-Info.plist" "$WIDGET_CONTENTS/Info.plist"
    
    # Sign widget extension with entitlements
    codesign --force --sign - --entitlements "$DIR/widget.entitlements" "$WIDGET_APPEX"
fi

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

# Clear extended attributes before signing to prevent macOS detritus rejection
xattr -cr "$BUNDLE_DIR"

# Sign Widget Extension first with sandbox entitlements
if [ -d "$WIDGET_APPEX" ]; then
    codesign --force --sign - --entitlements "$DIR/widget.entitlements" "$WIDGET_APPEX"
fi

# Sign Main App Bundle (preserving embedded appex signature)
codesign --force --sign - "$BUNDLE_DIR"

# Remove quarantine attribute if present
xattr -d com.apple.quarantine "$BUNDLE_DIR" 2>/dev/null || true

echo "==> Overnode.app successfully created and ready to launch at: $BUNDLE_DIR"
