#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MacStatsBar"
PRODUCT_NAME="MacStatsBarApp"
BUILD_DIR="${ROOT_DIR}/.build/release"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ICON_SOURCE_PNG="${ROOT_DIR}/mac_stat_icon.png"
ICON_NAME="AppIcon"

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "Building ${PRODUCT_NAME} (release)..."
swift build -c release --product "${PRODUCT_NAME}"

echo "Creating app bundle at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${PRODUCT_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if [[ -f "${ICON_SOURCE_PNG}" ]]; then
  ICONSET_DIR="${DIST_DIR}/${ICON_NAME}.iconset"
  rm -rf "${ICONSET_DIR}"
  mkdir -p "${ICONSET_DIR}"

  make_icon() {
    local size="$1"
    local filename="$2"
    sips -z "${size}" "${size}" "${ICON_SOURCE_PNG}" --out "${ICONSET_DIR}/${filename}" >/dev/null
  }

  make_icon 16 "icon_16x16.png"
  make_icon 32 "icon_16x16@2x.png"
  make_icon 32 "icon_32x32.png"
  make_icon 64 "icon_32x32@2x.png"
  make_icon 128 "icon_128x128.png"
  make_icon 256 "icon_128x128@2x.png"
  make_icon 256 "icon_256x256.png"
  make_icon 512 "icon_256x256@2x.png"
  make_icon 512 "icon_512x512.png"
  make_icon 1024 "icon_512x512@2x.png"

  iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/${ICON_NAME}.icns"
  rm -rf "${ICONSET_DIR}"
  echo "App icon installed from ${ICON_SOURCE_PNG}"
else
  echo "Warning: ${ICON_SOURCE_PNG} not found, app bundle will use default icon."
fi

cat > "${CONTENTS_DIR}/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>MacStatsBar</string>
    <key>CFBundleIdentifier</key>
    <string>dev.macstatsbar.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleName</key>
    <string>MacStatsBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

echo "Done. Bundle created:"
echo "  ${APP_DIR}"
echo
echo "Launch with:"
echo "  open \"${APP_DIR}\""
