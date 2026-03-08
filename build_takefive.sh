#!/bin/bash
set -e

# Workaround for macOS Gatekeeper incorrectly quarantining scripts in /var/folders/
export TMPDIR=/tmp


echo "=========================================================="
echo "🎬 TakeFive Custom FFmpeg Engine Builder (LGPL / arm64)"
echo "=========================================================="

# 1. Define Paths
BASE_DIR="$(pwd)"
SRC_DIR="${BASE_DIR}/src/ffmpeg"
OUT_DIR="${BASE_DIR}/takefive_prebuilt"
PREFIX="${OUT_DIR}/arm64"

# 2. Get Xcode SDK Paths
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CXX=$(xcrun --sdk iphoneos -f clang++)

echo "🛠️  Using SDK: ${SDK_PATH}"
echo "🧹 Cleaning previous builds..."
rm -rf "${OUT_DIR}"
mkdir -p "${PREFIX}"

# 3. Enter Source Directory
cd "${SRC_DIR}"

# 4. Configure FFmpeg (The heart of the build)
echo "⚙️  Configuring FFmpeg for iOS arm64..."
arch -arm64 env TMPDIR=/tmp bash ./configure \
    --prefix="${PREFIX}" \
    --enable-cross-compile \
    --target-os=darwin \
    --arch=arm64 \
    --sysroot="${SDK_PATH}" \
    --cc="${CC}" \
    --cxx="${CXX}" \
    --extra-cflags="-arch arm64 -miphoneos-version-min=15.1 -fembed-bitcode" \
    --extra-ldflags="-arch arm64 -miphoneos-version-min=15.1 -fembed-bitcode" \
    --disable-programs \
    --disable-doc \
    --disable-debug \
    --disable-asm \
    --enable-pic \
    --enable-videotoolbox \
    --enable-avfoundation \
    --disable-network \
    --enable-small \
    --enable-version3 \
    --disable-shared \
    --enable-static

# 5. Compile
echo "🔨 Compiling... (This will take a few minutes)"
make -j$(sysctl -n hw.ncpu)

# 6. Install
echo "📦 Installing to ${PREFIX}..."
make install

echo "✅ Build Successful! Files are in ${PREFIX}"
