#!/bin/bash
set -e

echo "=========================================================="
echo "📦 TakeFive Android AAR Builder"
echo "=========================================================="

BASE_DIR="$(pwd)"
ANDROID_DIR="${BASE_DIR}/android"
OUT_DIR="${BASE_DIR}/takefive_prebuilt_android"

if [[ ! -f "${OUT_DIR}/arm64-v8a/lib/libavcodec.a" ]]; then
  echo "❌ Static libs not found. Run build_takefive_android.sh first."
  exit 1
fi

if [[ -z "${ANDROID_SDK_ROOT}" ]]; then
  echo "❌ ANDROID_SDK_ROOT must be set"
  exit 1
fi

if [[ -z "${ANDROID_NDK_ROOT}" ]]; then
  echo "❌ ANDROID_NDK_ROOT must be set"
  exit 1
fi

cd "${ANDROID_DIR}"
chmod +x gradlew

echo "⚙️  Building ffmpeg-kit AAR (arm64-v8a, static FFmpeg)..."
./gradlew ffmpeg-kit-android-lib:assembleRelease --no-daemon 2>&1 || {
  echo "=== Gradle build failed — last 40 lines ==="
  cat "${ANDROID_DIR}/ffmpeg-kit-android-lib/build/reports/problems/problems-report.html" 2>/dev/null || true
  exit 1
}

AAR_SRC="${ANDROID_DIR}/ffmpeg-kit-android-lib/build/outputs/aar/ffmpeg-kit-release.aar"
AAR_DST="${OUT_DIR}/ffmpeg-kit.aar"

cp "${AAR_SRC}" "${AAR_DST}"
echo "✅ AAR built: ${AAR_DST} ($(du -sh "${AAR_DST}" | cut -f1))"
