#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/freetype"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android/dependencies/libfreetype"

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "❌ ANDROID_NDK_ROOT must be set" && exit 1
fi

API=21
TARGET=aarch64-linux-android
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
CC="${TOOLCHAIN}/bin/${TARGET}${API}-clang"
SYSROOT="${TOOLCHAIN}/sysroot"
CFLAGS="--sysroot=${SYSROOT} -target ${TARGET}${API} -O2"

echo "----------------------------------------------------------"
echo "🔨 Building FreeType for Android arm64-v8a"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

if [ -f Makefile ]; then
  make distclean || true
fi

./configure \
  --host=aarch64-linux-android \
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

make -j$(nproc)
make install

PC_FILE="${OUT_DIR}/lib/pkgconfig/freetype2.pc"
if [ -f "${PC_FILE}" ]; then
  sed -i 's/^Requires:.*$/Requires:/'               "${PC_FILE}"
  sed -i 's/^Requires\.private:.*$/Requires.private:/' "${PC_FILE}"
  sed -i 's/^Libs\.private:.*$/Libs.private:/'       "${PC_FILE}"
fi

echo "✅ FreeType (Android) build successful! Files in ${OUT_DIR}"
