#!/bin/zsh
set -e
cd "$(dirname "$0")"

APP="build/AJ139 Driver.app"
TMP=$(mktemp -d)
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP/AppIcon.iconset"

swiftc -O Tools/make_icon.swift -o "$TMP/make_icon"
"$TMP/make_icon" "$TMP/icon.png"
for size in 16 32 128 256 512; do
  sips -z $size $size "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${size}x${size}.png" >/dev/null
  sips -z $((size * 2)) $((size * 2)) "$TMP/icon.png" --out "$TMP/AppIcon.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$TMP/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

swiftc -O -parse-as-library Sources/*.swift -o "$APP/Contents/MacOS/AJ139Driver"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>AJ139Driver</string>
  <key>CFBundleIdentifier</key><string>io.github.werquess.aj139</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleName</key><string>AJ139 Driver</string>
  <key>CFBundleDisplayName</key><string>AJ139 Driver</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null 2>&1 || true
rm -rf "$TMP"
echo "$PWD/$APP"
