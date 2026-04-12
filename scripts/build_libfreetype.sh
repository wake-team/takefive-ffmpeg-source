#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/freetype"
OUT_DIR="${BASE_DIR}/takefive_prebuilt/dependencies/libfreetype"
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CFLAGS="-arch arm64 -miphoneos-version-min=15.1 -isysroot ${SDK_PATH} -fembed-bitcode"

echo "----------------------------------------------------------"
echo "🔨 Building FreeType for iOS arm64"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

# FreeType uses a standard autoconf system
# We disable harfbuzz for the first pass to avoid circular dependency
# We enable only essential modules for mobile to save space
if [ -f Makefile ]; then
    make distclean || true
fi

# Pass MAKE=make explicitly to avoid macOS make evaluation hangs
# Pipe /dev/null to prevent interactive prompts blocking the script
./configure \
    --host=arm-apple-darwin \
    --prefix="${OUT_DIR}" \
    --disable-shared \
    --enable-static \
    --without-harfbuzz \
    --without-png \
    --without-zlib \
    --without-bzip2 \
    --with-brotli=no \
    MAKE="make" \
    CC="${CC}" \
    CFLAGS="${CFLAGS}" \
    LDFLAGS="${CFLAGS}" < /dev/null

make -j$(sysctl -n hw.ncpu)
make install

# Strip all external Requires from the .pc file so pkg-config doesn't chase
# system libraries (brotli, zlib, etc.) that aren't in our PKG_CONFIG_PATH.
# We don't use WOFF2/brotli compressed fonts on mobile so this is safe.
PC_FILE="${OUT_DIR}/lib/pkgconfig/freetype2.pc"
if [ -f "${PC_FILE}" ]; then
    sed -i.bak 's/^Requires:.*$/Requires:/'               "${PC_FILE}"
    sed -i.bak 's/^Requires\.private:.*$/Requires.private:/' "${PC_FILE}"
    sed -i.bak 's/^Libs\.private:.*$/Libs.private:/'       "${PC_FILE}"
    echo "📝 Patched freetype2.pc (removed external Requires):"
    cat "${PC_FILE}"
else
    echo "⚠️  freetype2.pc not found at ${PC_FILE}"
    exit 1
fi

echo "✅ FreeType build successful! Files in ${OUT_DIR}"
