#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="iCleanerPro"
SCHEME="iCleanerPro"
CONFIGURATION="Release"
ARCHIVE_PATH="./build/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="./build/ipa"
EXPORT_OPTIONS="./ExportOptions.plist"

echo "==> Cleaning previous build artifacts..."
rm -rf ./build
mkdir -p ./build

echo "==> Archiving ${PROJECT_NAME} (${CONFIGURATION})..."
xcodebuild clean archive \
  -project "${PROJECT_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "generic/platform=iOS" \
  -archivePath "${ARCHIVE_PATH}" \
  ENABLE_BITCODE=NO

if [[ "${1:-}" == "--unsigned" ]]; then
  echo "==> Creating unsigned .ipa package (Payload/iCleanerPro.app)..."
  mkdir -p ./build/unsigned/Payload
  cp -R "${ARCHIVE_PATH}/Products/Applications/${PROJECT_NAME}.app" ./build/unsigned/Payload/
  (cd ./build/unsigned && zip -qr "../${PROJECT_NAME}-unsigned.ipa" Payload)
  echo "==> Unsigned IPA created at: ./build/${PROJECT_NAME}-unsigned.ipa"
else
  echo "==> Exporting signed .ipa using ${EXPORT_OPTIONS}..."
  xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "${EXPORT_OPTIONS}" \
    -allowProvisioningUpdates
  echo "==> Signed IPA exported to: ${EXPORT_PATH}/${PROJECT_NAME}.ipa"
fi
