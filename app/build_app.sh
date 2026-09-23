#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

VERSION="${1:-1.1.0}"
echo "==> Building Overnode v$VERSION for macOS (Apple Silicon)..."
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

# 2. Locate and copy resource bundle (CRITICAL: prevents static NSBundle.module crash)
BUNDLE_SOURCE=""
for CANDIDATE in \
    ".build/release/Overnode_Overnode.bundle" \
    ".build/out/Products/Release/Overnode_Overnode.bundle" \
    ".build/arm64-apple-macosx/release/Overnode_Overnode.bundle" \
    $(find .build -name "Overnode_Overnode.bundle" -type d 2>/dev/null | grep -i "release" | head -n 1) \
    $(find .build -name "Overnode_Overnode.bundle" -type d 2>/dev/null | head -n 1); do
    if [ -d "$CANDIDATE" ]; then
        BUNDLE_SOURCE="$CANDIDATE"
        break
    fi
done

if [ -n "$BUNDLE_SOURCE" ] && [ -d "$BUNDLE_SOURCE" ]; then
    echo "==> Copying resource bundle from $BUNDLE_SOURCE to $RESOURCES_DIR/"
    cp -R "$BUNDLE_SOURCE" "$RESOURCES_DIR/"
    # Also copy to MacOS dir as candidate fallback
    cp -R "$BUNDLE_SOURCE" "$MACOS_DIR/"
    # Copy to Root of Overnode.app (CRITICAL: prevents static NSBundle.module fatalError)
    cp -R "$BUNDLE_SOURCE" "$BUNDLE_DIR/"
    # Copy raw assets to Resources
    if [ -d "Sources/Overnode/Resources" ]; then
        cp -R Sources/Overnode/Resources/* "$RESOURCES_DIR/" 2>/dev/null || true
    fi
else
    echo "::error::Overnode_Overnode.bundle not found! Failing build to prevent crash at runtime."
    exit 1
fi

# 3. Locate and copy Widget Extension
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
    cp "$DIR/widget-Info.plist" "$WIDGET_CONTENTS/Info.plist"
    xattr -cr "$WIDGET_APPEX" 2>/dev/null || true; xattr -c "$WIDGET_APPEX" 2>/dev/null || true; codesign --force --sign - --entitlements "$DIR/widget.entitlements" "$WIDGET_APPEX"
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
