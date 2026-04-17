#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/lame/lame"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android/dependencies/libmp3lame"

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
echo "🔨 Building LAME for Android arm64-v8a"
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
  --disable-frontend \
  --disable-gtktest \
  CC="${CC}" \
  CFLAGS="${CFLAGS}" \
  LDFLAGS="${CFLAGS}"

make -j$(nproc)
make install

echo "✅ LAME (Android) build successful! Files in ${OUT_DIR}"
