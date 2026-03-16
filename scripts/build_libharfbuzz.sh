#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/harfbuzz"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libharfbuzz"
FREETYPE_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libfreetype"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CXX=$(xcrun --sdk iphoneos -f clang++)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode -I${FREETYPE_DIR}/include/freetype2"
LDFLAGS="-arch arm64 -miphoneos-version-min=15.1 -L${FREETYPE_DIR}/lib"

if [ -f "${OUT_DIR}/lib/libharfbuzz.a" ]; then
    echo "✅ HarfBuzz already built, skipping..."
    exit 0
fi

echo "----------------------------------------------------------"
echo "🔨 Building HarfBuzz for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

if [ -f Makefile ]; then
    make distclean || true
fi

# HarfBuzz often needs autogen/meson, but we will use standard configure if available
if [ ! -f configure ]; then
    ./autogen.sh
fi

./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --with-freetype=yes \
    --with-glib=no \
    --with-icu=no \
    --with-cairo=no \
    --with-fontconfig=no \
    CC="${CC}" \
    CXX="${CXX}" \
    CFLAGS="${CFLAGS}" \
    CXXFLAGS="${CFLAGS}" \
    LDFLAGS="${LDFLAGS}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ HarfBuzz build successful!"
