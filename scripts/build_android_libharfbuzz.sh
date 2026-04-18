#!/bin/bash
set -e

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASE_DIR}/src/harfbuzz"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android/dependencies/libharfbuzz"
FREETYPE_DIR="${BASE_DIR}/takefive_prebuilt_android/dependencies/libfreetype"

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "❌ ANDROID_NDK_ROOT must be set" && exit 1
fi

echo "----------------------------------------------------------"
echo "🔨 Building HarfBuzz for Android arm64-v8a"
echo "----------------------------------------------------------"

mkdir -p "${OUT_DIR}"
rm -rf "${SRC_DIR}/hb_build_android"

cmake -S "${SRC_DIR}" -B "${SRC_DIR}/hb_build_android" \
  -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_ROOT}/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${OUT_DIR}" \
  -DBUILD_SHARED_LIBS=OFF \
  -DHB_HAVE_FREETYPE=ON \
  -DFREETYPE_INCLUDE_DIRS="${FREETYPE_DIR}/include/freetype2" \
  -DFREETYPE_LIBRARY="${FREETYPE_DIR}/lib/libfreetype.a" \
  -DHB_HAVE_GLIB=OFF \
  -DHB_HAVE_ICU=OFF \
  -DHB_BUILD_TESTS=OFF \
  -DHB_BUILD_UTILITIES=OFF

cmake --build "${SRC_DIR}/hb_build_android" -j$(nproc)
cmake --install "${SRC_DIR}/hb_build_android"

# Always write a minimal self-contained .pc — no external Requires
mkdir -p "${OUT_DIR}/lib/pkgconfig"
PC_FILE="${OUT_DIR}/lib/pkgconfig/harfbuzz.pc"
cat > "${PC_FILE}" << EOF
prefix=${OUT_DIR}
exec_prefix=${OUT_DIR}
libdir=${OUT_DIR}/lib
includedir=${OUT_DIR}/include

Name: harfbuzz
Description: HarfBuzz text shaping library
Version: 8.0.1
Libs: -L${OUT_DIR}/lib -lharfbuzz -L${FREETYPE_DIR}/lib -lfreetype
Cflags: -I${OUT_DIR}/include/harfbuzz
EOF

echo "✅ HarfBuzz Android build complete → ${OUT_DIR}"
