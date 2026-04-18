#!/bin/bash
# Downloads prebuilt FFmpeg static libraries from GitHub Releases.
# Runs automatically after `yarn install` or `npm install`.
# Also renames FFmpegKitReactNativeModule.m -> .mm for ObjC++ compatibility.
set -e

# Package root is one level up from this script's directory
PKG_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PREBUILT_DIR="${PKG_ROOT}/takefive_prebuilt"
IOS_DIR="${PKG_ROOT}/react-native/ios"

# Read version from package.json
VERSION=$(node -e "process.stdout.write(require('${PKG_ROOT}/package.json').version)")
RELEASE_TAG="v${VERSION}"
DOWNLOAD_URL="https://github.com/wake-team/takefive-ffmpeg-source/releases/download/${RELEASE_TAG}/takefive_prebuilt.tar.gz"

# ── 1. Ensure FFmpegKitReactNativeModule is .mm (ObjC++) ────────────────────
if [ -f "${IOS_DIR}/FFmpegKitReactNativeModule.m" ] && [ ! -f "${IOS_DIR}/FFmpegKitReactNativeModule.mm" ]; then
  mv "${IOS_DIR}/FFmpegKitReactNativeModule.m" "${IOS_DIR}/FFmpegKitReactNativeModule.mm"
  echo "✅ takefive-ffmpeg-kit: Renamed FFmpegKitReactNativeModule.m → .mm"
fi

# ── 2. Download prebuilt if not already present ─────────────────────────────
if [ -f "${PREBUILT_DIR}/arm64/lib/libavcodec.a" ]; then
  echo "✅ takefive-ffmpeg-kit: Prebuilt libraries already present. Skipping download."
else
  echo "📦 takefive-ffmpeg-kit: Downloading prebuilt FFmpeg libraries (${RELEASE_TAG})..."

  TMP_TAR="/tmp/takefive-ffmpeg-prebuilt-${RELEASE_TAG}.tar.gz"

  curl -L -o "${TMP_TAR}" "${DOWNLOAD_URL}" 2>/dev/null || {
    echo "❌ Failed to download prebuilt libraries from ${DOWNLOAD_URL}"
    echo "   Please download manually and extract to ${PREBUILT_DIR}/"
    exit 1
  }

  mkdir -p "${PREBUILT_DIR}"
  tar -xzf "${TMP_TAR}" -C "${PKG_ROOT}"
  rm -f "${TMP_TAR}"

  echo "✅ takefive-ffmpeg-kit: Prebuilt libraries installed to ${PREBUILT_DIR}/"
fi

# ── 3. Copy internal FFmpeg headers not installed by make install ────────────
# These are needed by fftools source files but excluded from the public API.
AVUTIL_DIR="${PREBUILT_DIR}/arm64/include/libavutil"
SRC_FFMPEG="${PKG_ROOT}/src/ffmpeg/libavutil"

INTERNAL_HEADERS="thread.h internal.h libm.h getenv_utf8.h wchar_filename.h"

if [ -d "${AVUTIL_DIR}" ] && [ -d "${SRC_FFMPEG}" ]; then
  for h in $INTERNAL_HEADERS; do
    if [ ! -f "${AVUTIL_DIR}/${h}" ] && [ -f "${SRC_FFMPEG}/${h}" ]; then
      cp "${SRC_FFMPEG}/${h}" "${AVUTIL_DIR}/${h}"
      echo "  → Copied internal header: ${h}"
    fi
  done
fi

# ── 4. Download Android AAR ───────────────────────────────────────────────────
ANDROID_PREBUILT_DIR="${PKG_ROOT}/takefive_prebuilt_android"
ANDROID_AAR="${ANDROID_PREBUILT_DIR}/ffmpeg-kit.aar"
ANDROID_AAR_URL="https://github.com/wake-team/takefive-ffmpeg-source/releases/download/${RELEASE_TAG}/takefive-ffmpeg-android.aar"

if [ -f "${ANDROID_AAR}" ]; then
  echo "✅ takefive-ffmpeg-kit: Android AAR already present. Skipping download."
else
  echo "📦 takefive-ffmpeg-kit: Downloading Android AAR (${RELEASE_TAG})..."
  mkdir -p "${ANDROID_PREBUILT_DIR}"
  curl -L -o "${ANDROID_AAR}" "${ANDROID_AAR_URL}" 2>/dev/null || {
    echo "⚠️  takefive-ffmpeg-kit: Could not download Android AAR from ${ANDROID_AAR_URL}"
    echo "   Android builds will fail until the AAR is available."
    # Don't exit — iOS-only installs should still succeed
    true
  }
  if [ -f "${ANDROID_AAR}" ]; then
    echo "✅ takefive-ffmpeg-kit: Android AAR installed to ${ANDROID_AAR}"
  fi
fi
