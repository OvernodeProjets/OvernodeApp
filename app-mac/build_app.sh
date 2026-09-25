#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

VERSION="${1:-1.1.0}"
SIGNING_IDENTITY="${2:-${SIGNING_IDENTITY:--}}"
echo "==> Building Overnode v$VERSION for macOS (Apple Silicon)..."
swift build -c release

APP_NAME="Overnode"
FINAL_BUNDLE_DIR="$DIR/build/$APP_NAME.app"
TEMP_BUILD="$(mktemp -d)"
BUNDLE_DIR="$TEMP_BUILD/$APP_NAME.app"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
PLUGINS_DIR="$CONTENTS_DIR/PlugIns"
WIDGET_APPEX="$PLUGINS_DIR/OvernodeWidgetExtension.appex"
WIDGET_CONTENTS="$WIDGET_APPEX/Contents"
WIDGET_MACOS="$WIDGET_CONTENTS/MacOS"

echo "==> Creating Application Bundle (temp: $TEMP_BUILD)..."
rm -rf "$FINAL_BUNDLE_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$PLUGINS_DIR"
mkdir -p "$WIDGET_MACOS"

# 1. Locate and copy main binary
BIN_SOURCE=""
for CANDIDATE in \
    ".build/release/$APP_NAME" \
    ".build/out/Products/Release/$APP_NAME" \
    ".build/arm64-apple-macosx/release/$APP_NAME" \
    $(find .build -name "$APP_NAME" -type f -perm +111 2>/dev/null | grep -i "release" | head -n 1); do
    if [ -f "$CANDIDATE" ]; then
        BIN_SOURCE="$CANDIDATE"
        break
    fi
done

if [ -n "$BIN_SOURCE" ] && [ -f "$BIN_SOURCE" ]; then
    echo "==> Using main binary: $BIN_SOURCE"
    cp "$BIN_SOURCE" "$MACOS_DIR/$APP_NAME"
    chmod +x "$MACOS_DIR/$APP_NAME"
else
    echo "::error::Binary $APP_NAME not found in .build!"
    exit 1
fi

# 2. Copy native resources directly to Contents/Resources/
if [ -d "Sources/Overnode/Resources" ]; then
    echo "==> Copying resources from Sources/Overnode/Resources to $RESOURCES_DIR/"
    xattr -cr Sources/Overnode/Resources 2>/dev/null || true
    cp -R Sources/Overnode/Resources/* "$RESOURCES_DIR/"
    mkdir -p "$RESOURCES_DIR/Overnode_Overnode.bundle"
    cp -R Sources/Overnode/Resources/* "$RESOURCES_DIR/Overnode_Overnode.bundle/"
    xattr -cr "$RESOURCES_DIR" 2>/dev/null || true
fi

# 3. Locate and copy Widget Extension binary (built by SPM as MH_EXECUTE with _NSExtensionMain entry)
WIDGET_SOURCE=""
for CANDIDATE in \
    ".build/release/OvernodeWidgetExtension" \
    ".build/out/Products/Release/OvernodeWidgetExtension" \
    ".build/arm64-apple-macosx/release/OvernodeWidgetExtension" \
    $(find .build -name "OvernodeWidgetExtension" -type f -perm +111 2>/dev/null | grep -i "release" | head -n 1); do
    if [ -f "$CANDIDATE" ]; then
        WIDGET_SOURCE="$CANDIDATE"
        break
    fi
done

if [ -n "$WIDGET_SOURCE" ] && [ -f "$WIDGET_SOURCE" ]; then
    echo "==> Using widget extension binary: $WIDGET_SOURCE"
    cp "$WIDGET_SOURCE" "$WIDGET_MACOS/OvernodeWidgetExtension"
    chmod +x "$WIDGET_MACOS/OvernodeWidgetExtension"
    sed "s/<string>1.0.0<\/string>/<string>$VERSION<\/string>/g" "$DIR/widget-Info.plist" > "$WIDGET_CONTENTS/Info.plist"
else
    echo "WARNING: Widget extension binary not found, skipping widget"
fi

# 4. Create Info.plist with version
cat << EOF > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>fr</string>
    <key>CFBundleExecutable</key>
    <string>Overnode</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>fr.overnode.OvernodeApp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Overnode</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
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

# 5. Clean attributes & ad-hoc sign bundle
dot_clean "$BUNDLE_DIR" 2>/dev/null || true
xattr -cr "$BUNDLE_DIR" 2>/dev/null || true
find "$BUNDLE_DIR" -exec xattr -c {} \; 2>/dev/null || true

# 1. Sign widget extension FIRST with its own entitlements (inside-out signing)
if [ -d "$WIDGET_APPEX" ]; then
    xattr -cr "$WIDGET_APPEX" 2>/dev/null || true
    if [ "$SIGNING_IDENTITY" = "-" ]; then
        codesign --force --sign - --entitlements "$DIR/widget.entitlements" "$WIDGET_APPEX"
    else
        codesign --force --options runtime --sign "$SIGNING_IDENTITY" --entitlements "$DIR/widget.entitlements" "$WIDGET_APPEX"
    fi
fi

# 2. Sign main app bundle SECOND (WITHOUT --deep so nested extension signature & entitlements are preserved!)
if [ "$SIGNING_IDENTITY" = "-" ]; then
    codesign --force --sign - --entitlements "$DIR/app.entitlements" "$BUNDLE_DIR"
else
    codesign --force --options runtime --sign "$SIGNING_IDENTITY" --entitlements "$DIR/app.entitlements" "$BUNDLE_DIR"
fi

# 3. Verify signature integrity
codesign --verify --deep --strict --verbose=2 "$BUNDLE_DIR"

echo "==> Successfully created and signed Overnode.app"

# 6. Move to final location
mkdir -p "$DIR/build"
rm -rf "$FINAL_BUNDLE_DIR"
ditto "$BUNDLE_DIR" "$FINAL_BUNDLE_DIR"
rm -rf "$TEMP_BUILD"
echo "==> Application bundle ready at $FINAL_BUNDLE_DIR"

# 7. Update /Applications/Overnode.app if it exists
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "==> Updating /Applications/$APP_NAME.app..."
    rm -rf "/Applications/$APP_NAME.app"
    ditto "$FINAL_BUNDLE_DIR" "/Applications/$APP_NAME.app"
    # Register updated widget extension
    /usr/bin/pluginkit -a "/Applications/$APP_NAME.app/Contents/PlugIns/OvernodeWidgetExtension.appex" 2>/dev/null || true
    # Restart widget and notification center daemons to immediately flush widget cache
    killall -9 chronod NotificationCenter 2>/dev/null || true
    echo "==> /Applications/$APP_NAME.app updated successfully (widget cache flushed)"
fi
