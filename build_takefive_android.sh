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

# 7. Configure & Build FFmpeg
echo "=== PKG_CONFIG_PATH ==="
echo "${PKG_CONFIG_PATH}"
HB_PC="${DEPS_BASE_DIR}/libharfbuzz/lib/pkgconfig/harfbuzz.pc"
if [ -f "${HB_PC}" ]; then
  echo "=== harfbuzz.pc ==="
  cat "${HB_PC}"
  echo "=== pkg-config test ==="
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --exists harfbuzz && echo "pkg-config OK" || echo "pkg-config FAILED"
  PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" pkg-config --cflags --libs harfbuzz 2>&1 || true
else
  echo "harfbuzz.pc NOT FOUND at ${HB_PC}"
fi

cd "${SRC_DIR}"
echo "⚙️  Configuring FFmpeg for Android arm64-v8a..."

PKG_CONFIG_PATH="${PKG_CONFIG_PATH}" bash ./configure \
  --pkg-config="$(which pkg-config)" \
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
  --enable-mediacodec --enable-jni \
  --enable-encoder=h264_mediacodec --enable-decoder=h264_mediacodec \
  --enable-filter=eq,colorbalance,scale,pad,setsar,fps,trim,setpts,atrim,asetpts,atempo,concat,anullsrc,aloop,volume,sidechaincompress,amix,aevalsrc,overlay,drawtext \
  "${FFMPEG_EXTRA_FLAGS[@]}" < /dev/null || {
  echo "=== FFmpeg configure failed — last 80 lines of ffbuild/config.log ==="
  tail -80 ffbuild/config.log 2>/dev/null || true
  exit 1
}

make -j$(nproc)
make install

echo "✅ Android Build Successful! Files in ${PREFIX}"
