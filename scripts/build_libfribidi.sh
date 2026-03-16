#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/fribidi"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libfribidi"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode"

if [ -f "${OUT_DIR}/lib/libfribidi.a" ]; then
    echo "✅ Fribidi already built, skipping..."
    exit 0
fi

echo "----------------------------------------------------------"
echo "🔨 Building Fribidi for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

if [ -f Makefile ]; then
    make distclean || true
fi

# Fribidi requires autogen if configure is missing
if [ ! -f configure ]; then
    ./autogen.sh
fi

./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --disable-debug \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${CFLAGS}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ Fribidi build successful!"
