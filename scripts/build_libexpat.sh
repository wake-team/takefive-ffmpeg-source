#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/expat/expat"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libexpat"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode"

if [ -f "${OUT_DIR}/lib/libexpat.a" ]; then
    echo "✅ Expat already built, skipping..."
    exit 0
fi

echo "----------------------------------------------------------"
echo "🔨 Building Expat for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

if [ -f Makefile ]; then
    make distclean || true
fi

./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --without-docbook \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${CFLAGS}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ Expat build successful!"
