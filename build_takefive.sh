#!/bin/bash
set -e

echo "=========================================================="
echo "🎬 TakeFive Dynamic FFmpeg Engine Builder"
echo "=========================================================="

# 1. Paths
BASE_DIR="$(pwd)"
SRC_DIR="${BASE_DIR}/src/ffmpeg"
OUT_DIR="${BASE_DIR}/takefive_prebuilt"
PREFIX="${OUT_DIR}/arm64"
DEPS_BASE_DIR="${OUT_DIR}/dependencies"

# 2. SDK Setup
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
CC=$(xcrun --sdk iphoneos -f clang)
CXX=$(xcrun --sdk iphoneos -f clang++)

# 3. Dynamic Flag Processing
FFMPEG_EXTRA_FLAGS=()
FFMPEG_CFLAGS=("-arch arm64 -miphoneos-version-min=15.1")
FFMPEG_LDFLAGS=("-arch arm64 -miphoneos-version-min=15.1")

# Ensure deps dir exists
mkdir -p "${DEPS_BASE_DIR}"

# 4. FIX macOS DYLD FREEZE
# Exporting TMPDIR to a local path bypasses EndpointSecurity bugs on /var/folders
export TMPDIR="${BASE_DIR}/build_tmp"
mkdir -p "${TMPDIR}"

# Fetch all sources first
bash ./scripts/fetch_deps.sh

# 5. Fix FFmpeg Makefiles and scripts to bypass macOS execution bugs
bash ./patch_ffmpeg.sh

for arg in "$@"; do
  case $arg in
    --enable-*)
      LIB_NAME=$(echo $arg | sed 's/--enable-//')
      BUILD_SCRIPT="./scripts/build_${LIB_NAME}.sh"
      
      if [ -f "$BUILD_SCRIPT" ]; then
        echo "🔌 Injecting dependency: ${LIB_NAME}..."
        bash "$BUILD_SCRIPT"
        
        LIB_PATH="${DEPS_BASE_DIR}/${LIB_NAME}"
        FFMPEG_EXTRA_FLAGS+=("$arg")
        FFMPEG_CFLAGS+=("-I${LIB_PATH}/include")
        FFMPEG_LDFLAGS+=("-L${LIB_PATH}/lib")
        export PKG_CONFIG_PATH="${LIB_PATH}/lib/pkgconfig:${PKG_CONFIG_PATH}"
      else
        echo "⚠️  No build script found for ${LIB_NAME}, skipping..."
      fi
      ;;
  esac
done

# 4. Configure & Build FFmpeg
cd "${SRC_DIR}"
echo "⚙️  Configuring FFmpeg with injected flags: ${FFMPEG_EXTRA_FLAGS[*]}"

mkdir -p "${BASE_DIR}/build_tmp"
arch -arm64 env TMPDIR="${BASE_DIR}/build_tmp" bash ./configure \
    --prefix="${PREFIX}" \
    --enable-cross-compile \
    --target-os=darwin \
    --arch=arm64 \
    --sysroot="${SDK_PATH}" \
    --cc="${CC}" \
    --cxx="${CXX}" \
    --extra-cflags="${FFMPEG_CFLAGS[*]}" \
    --extra-ldflags="${FFMPEG_LDFLAGS[*]}" \
    --disable-programs --disable-doc --disable-debug --disable-asm \
    --enable-pic --enable-videotoolbox --enable-avfoundation --disable-audiotoolbox \
    --enable-small --enable-version3 --disable-shared --enable-static \
    "${FFMPEG_EXTRA_FLAGS[@]}" < /dev/null

make -j$(sysctl -n hw.ncpu)
make install

echo "✅ Dynamic Build Successful! Files in ${PREFIX}"
