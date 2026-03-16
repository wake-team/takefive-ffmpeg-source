#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/lame/lame"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/lame"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode -Wno-implicit-function-declaration"

echo "----------------------------------------------------------"
echo "🔨 Building LAME for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

# If configure doesn't exist, run autogen or just use it if it's there
# Note: LAME usually has a configure script, let's check it.
if [ ! -f configure ]; then
    echo "⚠️  Configure script missing, trying to find it..."
    ls -la
    exit 1
fi

# Clean if previously built
if [ -f Makefile ]; then
    make distclean || true
fi

# Configure for iOS cross-compilation
# Note: we use --disable-shared for a static build to simplify LGPL linking
./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --disable-frontend \
    --disable-gtktest \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${CFLAGS}"

make -j$(sysctl -n hw.ncpu)
make install

echo "✅ LAME build successful! Files in ${OUT_DIR}"
