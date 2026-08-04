#!/bin/bash
set -euo pipefail

# ============================================================
# Xulora .app Bundle Build Script
# Produces a macOS application bundle from the SPM project.
# ============================================================

APP_NAME="Xulora"
DISPLAY_NAME="桌序"
BUNDLE_ID="com.nuochong.xulora"
VERSION="0.1.0"
BUILD_CONFIG="${1:-release}"
BUILD_DIR=".build/app/${BUILD_CONFIG}"

echo "=== Building Xulora ${VERSION} (${BUILD_CONFIG}) ==="

# Step 1: Build the executable
swift build -c "${BUILD_CONFIG}" --arch arm64

# Step 2: Determine executable path
if [ "${BUILD_CONFIG}" = "release" ]; then
    EXEC_PATH=".build/arm64-apple-macosx/release/${APP_NAME}"
else
    EXEC_PATH=".build/arm64-apple-macosx/debug/${APP_NAME}"
fi

if [ ! -f "${EXEC_PATH}" ]; then
    echo "ERROR: Executable not found at ${EXEC_PATH}"
    exit 1
fi

echo "=== Creating .app bundle ==="

# Step 3: Clean and create bundle structure
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources"

# Step 4: Copy executable
cp "${EXEC_PATH}" "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"
chmod +x "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}"

# Step 5: Generate Info.plist with correct values
cat > "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>zh_CN</string>
	<key>CFBundleDisplayName</key>
	<string>${DISPLAY_NAME}</string>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>26.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright (c) 2026 诺崇. All rights reserved.</string>
</dict>
</plist>
PLIST

echo "=== Bundle created ==="
echo "Path: ${BUILD_DIR}/${APP_NAME}.app"
echo ""

# Step 6: Verify bundle
echo "=== Verification ==="
echo "Executable: $(file "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}")"
echo "Bundle ID: $(plutil -p "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist" | grep CFBundleIdentifier)"
echo ""

# Step 7: Create ZIP archive
ZIP_NAME="${APP_NAME}-${VERSION}-${BUILD_CONFIG}.zip"
rm -f "${BUILD_DIR}/${ZIP_NAME}"

cd "${BUILD_DIR}"
zip -qr "${ZIP_NAME}" "${APP_NAME}.app"
cd - > /dev/null

echo "=== Package: ${BUILD_DIR}/${ZIP_NAME} ==="
echo "Size: $(du -sh "${BUILD_DIR}/${ZIP_NAME}" | cut -f1)"
echo ""
echo "Done. You can now open ${APP_NAME}.app directly or distribute the zip."
