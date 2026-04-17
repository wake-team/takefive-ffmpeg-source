#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/openh264"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android/dependencies/libopenh264"

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "❌ ANDROID_NDK_ROOT must be set" && exit 1
fi

API=21
TARGET=aarch64-linux-android
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
CC="${TOOLCHAIN}/bin/${TARGET}${API}-clang"
CXX="${TOOLCHAIN}/bin/${TARGET}${API}-clang++"
AR="${TOOLCHAIN}/bin/llvm-ar"
SYSROOT="${TOOLCHAIN}/sysroot"
CFLAGS="--sysroot=${SYSROOT} -target ${TARGET}${API} -DHAVE_NEON_AARCH64 -DANDROID_NDK -I${ANDROID_NDK_ROOT}/sources/android/cpufeatures"

echo "----------------------------------------------------------"
echo "🔨 Building OpenH264 for Android arm64-v8a"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
cd "${SRC_DIR}"

make clean 2>/dev/null || true

# Disable cpu-features injection from NDK (avoids linker issues with static build)
sed -i 's/^COMMON_INCLUDES +=/# COMMON_INCLUDES +=/' build/platform-android.mk || true
sed -i 's/^COMMON_OBJS +=/# COMMON_OBJS +=/' build/platform-android.mk || true
sed -i 's/^COMMON_CFLAGS +=/# COMMON_CFLAGS +=/' build/platform-android.mk || true

make -j$(nproc) \
  OS=android \
  ARCH=arm64 \
  CC="${CC}" \
  CXX="${CXX}" \
  AR="${AR}" \
  CFLAGS="${CFLAGS}" \
  CXXFLAGS="${CFLAGS}" \
  NDKROOT="${ANDROID_NDK_ROOT}" \
  NDK_TOOLCHAIN_VERSION=clang \
  TARGET="android-${API}" \
  PREFIX="${OUT_DIR}" \
  install-static

# Manually copy lib/headers if install-static didn't place them (Makefile version variance)
mkdir -p "${OUT_DIR}/lib" "${OUT_DIR}/include/wels"
if [ ! -f "${OUT_DIR}/lib/libopenh264.a" ]; then
  echo "install-static missed the .a — copying manually..."
  find "${SRC_DIR}" -name "libopenh264.a" | head -1 | xargs -I{} cp {} "${OUT_DIR}/lib/"
fi
if [ -z "$(ls -A "${OUT_DIR}/include/wels" 2>/dev/null)" ]; then
  cp "${SRC_DIR}"/codec/api/wels/*.h "${OUT_DIR}/include/wels/"
fi

# Generate pkg-config file for FFmpeg's configure (always overwrite to ensure correct path)
mkdir -p "${OUT_DIR}/lib/pkgconfig"
cat > "${OUT_DIR}/lib/pkgconfig/openh264.pc" << EOF
prefix=${OUT_DIR}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: openh264
Description: H.264 codec library
Version: 2.3.1
Libs: -L\${libdir} -lopenh264
Cflags: -I\${includedir}
EOF

echo "=== OpenH264 install verification ==="
ls -la "${OUT_DIR}/lib/" || true
cat "${OUT_DIR}/lib/pkgconfig/openh264.pc" || true

echo "✅ OpenH264 (Android) build successful! Files in ${OUT_DIR}"
