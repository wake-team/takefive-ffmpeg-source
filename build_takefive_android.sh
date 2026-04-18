#!/bin/bash
set -e

echo "=========================================================="
echo "🤖 TakeFive Android FFmpeg Engine Builder"
echo "=========================================================="

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "❌ ANDROID_NDK_ROOT must be set (e.g. export ANDROID_NDK_ROOT=\$ANDROID_SDK_ROOT/ndk/27.2.12479018)"
  exit 1
fi

# 1. Paths
BASE_DIR="$(pwd)"
SRC_DIR="${BASE_DIR}/src/ffmpeg"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android"
PREFIX="${OUT_DIR}/arm64-v8a"
DEPS_BASE_DIR="${OUT_DIR}/dependencies"

# 2. NDK Toolchain Setup
API=21
TARGET=aarch64-linux-android
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"
SYSROOT="${TOOLCHAIN}/sysroot"

export CC="${TOOLCHAIN}/bin/${TARGET}${API}-clang"
export CXX="${TOOLCHAIN}/bin/${TARGET}${API}-clang++"
export AR="${TOOLCHAIN}/bin/llvm-ar"
export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
export STRIP="${TOOLCHAIN}/bin/llvm-strip"

# 3. Dynamic Flag Processing
FFMPEG_EXTRA_FLAGS=()
FFMPEG_CFLAGS=("--sysroot=${SYSROOT}" "-target ${TARGET}${API}")
FFMPEG_LDFLAGS=("--sysroot=${SYSROOT}" "-target ${TARGET}${API}")

mkdir -p "${DEPS_BASE_DIR}"

# 4. Fetch all sources
bash ./scripts/fetch_deps.sh

# 5. Patch FFmpeg build scripts (cross-platform)
bash ./patch_ffmpeg.sh

# 6. Build requested dependency libraries
for arg in "$@"; do
  case $arg in
    --enable-*)
      LIB_NAME=$(echo "$arg" | sed 's/--enable-//')
      BUILD_SCRIPT="./scripts/build_android_${LIB_NAME}.sh"

      if [ -f "$BUILD_SCRIPT" ]; then
        echo "🔌 Injecting Android dependency: ${LIB_NAME}..."
        bash "$BUILD_SCRIPT"

        LIB_PATH="${DEPS_BASE_DIR}/${LIB_NAME}"
        FFMPEG_EXTRA_FLAGS+=("$arg")
        FFMPEG_CFLAGS+=("-I${LIB_PATH}/include")
        FFMPEG_LDFLAGS+=("-L${LIB_PATH}/lib")
        export PKG_CONFIG_PATH="${LIB_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH}"
      else
        echo "⚠️  No Android build script found for ${LIB_NAME}, skipping..."
      fi
      ;;
  esac
done

# 7. Verify dependency pkg-config files before configure
echo "=== PKG_CONFIG_PATH: ${PKG_CONFIG_PATH} ==="
for pcdir in $(echo "${PKG_CONFIG_PATH}" | tr ':' '\n'); do
  echo "--- ${pcdir} ---"
  ls "${pcdir}"/*.pc 2>/dev/null || echo "  (no .pc files)"
done

# 8. Configure & Build FFmpeg
cd "${SRC_DIR}"
echo "⚙️  Configuring FFmpeg for Android arm64-v8a..."

echo "=== pkg-config openh264 self-test ==="
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --exists openh264 && echo "EXISTS ok" || echo "EXISTS FAILED"
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --modversion openh264 2>&1 || true
PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --cflags --libs --static openh264 2>&1 || true

echo "=== manual openh264 compile+link test ==="
OPENH264_INC=$(PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --cflags openh264 2>/dev/null)
OPENH264_LIB=$(PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --static --libs openh264 2>/dev/null)
cat > /tmp/test_openh264.cpp << 'EOF'
#include "openh264/codec_api.h"
int main() { ISVCEncoder *enc = nullptr; WelsCreateSVCEncoder(&enc); return 0; }
EOF
echo "-- compile --"
${CXX} --sysroot="${SYSROOT}" -target ${TARGET}${API} ${OPENH264_INC} -c /tmp/test_openh264.cpp -o /tmp/test_openh264.o && echo "compile OK" || echo "compile FAILED"
echo "-- link --"
${CXX} --sysroot="${SYSROOT}" -target ${TARGET}${API} /tmp/test_openh264.o ${OPENH264_LIB} -o /tmp/test_openh264_bin && echo "link OK" || echo "link FAILED"

PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" bash ./configure \
  --prefix="${PREFIX}" \
  --enable-cross-compile \
  --target-os=android \
  --arch=aarch64 \
  --cpu=armv8-a \
  --sysroot="${SYSROOT}" \
  --cc="${CC}" \
  --cxx="${CXX}" \
  --ar="${AR}" \
  --ranlib="${RANLIB}" \
  --strip="${STRIP}" \
  --extra-cflags="${FFMPEG_CFLAGS[*]}" \
  --extra-ldflags="${FFMPEG_LDFLAGS[*]}" \
  --extra-libs="-lc++ -lm" \
  --disable-programs --disable-doc --disable-debug --disable-asm \
  --enable-pic \
  --enable-small --enable-version3 --disable-shared --enable-static \
  --enable-filter=eq,colorbalance,scale,pad,setsar,fps,trim,setpts,atrim,asetpts,atempo,concat,anullsrc,aloop,volume,sidechaincompress,amix,aevalsrc,overlay,drawtext \
  "${FFMPEG_EXTRA_FLAGS[@]}" < /dev/null || {
  echo "=== FFmpeg configure failed — grep openh264 from config.log ==="
  grep -A 30 "check_pkg_config.*openh264\|openh264.*not found\|WelsCreate" ffbuild/config.log 2>/dev/null | head -100 || true
  echo "=== last 120 lines of ffbuild/config.log ==="
  tail -120 ffbuild/config.log 2>/dev/null || true
  exit 1
}

make -j$(nproc)
make install

echo "✅ Android Build Successful! Files in ${PREFIX}"
