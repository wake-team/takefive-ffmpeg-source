#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/libass"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libass"
DEPS_DIR="${BASE_DIR}/takefive_prebuilt/dependencies"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode"

# Paths to dependencies
FT_PATH="${DEPS_DIR}/libfreetype"
HB_PATH="${DEPS_DIR}/libharfbuzz"
FB_PATH="${DEPS_DIR}/libfribidi"
EX_PATH="${DEPS_DIR}/libexpat"

INC_FLAGS="-I${FT_PATH}/include/freetype2 -I${HB_PATH}/include/harfbuzz -I${FB_PATH}/include -I${EX_PATH}/include"
LD_FLAGS="-L${FT_PATH}/lib -L${HB_PATH}/lib -L${FB_PATH}/lib -L${EX_PATH}/lib"

if [ -f "${OUT_DIR}/lib/libass.a" ]; then
    echo "✅ Libass already built, skipping..."
    exit 0
fi

echo "----------------------------------------------------------"
echo "🔨 Building Libass for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

if [ -f Makefile ]; then
    make distclean || true
fi

if [ ! -f configure ]; then
    ./autogen.sh
fi

./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --enable-harfbuzz \
    --enable-asm \
    --disable-require-system-font-provider \
    CC="${CC}" \
    CFLAGS="${CFLAGS} ${INC_FLAGS}" \
    LDFLAGS="${CFLAGS} ${LD_FLAGS}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ Libass build successful!"
