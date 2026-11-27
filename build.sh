#!/bin/bash
# CutPaste build script — builds CutPaste.app (ad-hoc signed, universal).
# Usage: ./build.sh
set -e
cd "$(dirname "$0")"

APP="CutPaste.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> Compiling (arm64 + x86_64)…"
for ARCH in arm64 x86_64; do
  swiftc -O -target "$ARCH-apple-macosx13.0" \
    -framework Cocoa -framework ApplicationServices -framework ServiceManagement \
    main.swift -o "CutPaste-$ARCH"
done
lipo -create "CutPaste-arm64" "CutPaste-x86_64" -output "$APP/Contents/MacOS/CutPaste"
rm -f "CutPaste-arm64" "CutPaste-x86_64"

echo "==> Icon…"
swift makeicon.swift icon-1024.png
rm -rf AppIcon.iconset
mkdir AppIcon.iconset
for S in 16 32 128 256 512; do
  sips -z "$S" "$S" icon-1024.png --out "AppIcon.iconset/icon_${S}x${S}.png" >/dev/null
  D=$((S * 2))
  sips -z "$D" "$D" icon-1024.png --out "AppIcon.iconset/icon_${S}x${S}@2x.png" >/dev/null
done
iconutil -c icns AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf AppIcon.iconset icon-1024.png

echo "==> Localizations (en, es)…"
cp -R en.lproj es.lproj "$APP/Contents/Resources/"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>CutPaste</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>CutPaste</string>
	<key>CFBundleIdentifier</key>
	<string>dev.abadx.findercut</string>
	<key>CFBundleVersion</key>
	<string>2</string>
	<key>CFBundleShortVersionString</key>
	<string>1.2.0</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleExecutable</key>
	<string>CutPaste</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>LSUIElement</key>
	<true/>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>NSHumanReadableCopyright</key>
	<string>© 2026 AbadXDev — MIT License</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "$APP"

echo "BUILD_OK $APP"
