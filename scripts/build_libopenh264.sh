#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/openh264"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/openh264"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)

echo "----------------------------------------------------------"
echo "🔨 Building OpenH264 for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

# OpenH264 uses a custom Makefile system, not autoconf
make clean || true
make -j$(sysctl -n hw.ncpu) OS=ios ARCH=arm64 \
    SDKMIN=15.1 \
    PREFIX="${OUT_DIR}" \
    install-static

echo "✅ OpenH264 build successful! Files in ${OUT_DIR}"
