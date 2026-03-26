#!/bin/bash
# Downloads prebuilt FFmpeg static libraries from GitHub Releases.
# This script runs automatically after `yarn install` or `npm install`.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PREBUILT_DIR="${SCRIPT_DIR}/takefive_prebuilt"
RELEASE_TAG="v1.0.0"
DOWNLOAD_URL="https://github.com/wake-team/takefive-ffmpeg-source/releases/download/${RELEASE_TAG}/takefive-ffmpeg-ios.zip"

# Skip if prebuilt libraries already exist
if [ -f "${PREBUILT_DIR}/arm64/lib/libavcodec.a" ]; then
  echo "✅ takefive-ffmpeg-kit: Prebuilt libraries already present. Skipping download."
  exit 0
fi

echo "📦 takefive-ffmpeg-kit: Downloading prebuilt FFmpeg libraries from release ${RELEASE_TAG}..."

TMP_ZIP="/tmp/takefive-ffmpeg-ios-${RELEASE_TAG}.zip"

# Download
curl -L -o "${TMP_ZIP}" "${DOWNLOAD_URL}" 2>/dev/null || {
  echo "❌ Failed to download prebuilt libraries from ${DOWNLOAD_URL}"
  echo "   Please download manually and extract to ${PREBUILT_DIR}/"
  exit 1
}

# Extract
mkdir -p "${PREBUILT_DIR}"
unzip -o -q "${TMP_ZIP}" -d "${PREBUILT_DIR}"

# Also copy config.h from the FFmpeg source if available locally
if [ -f "${SCRIPT_DIR}/src/ffmpeg/config.h" ]; then
  cp "${SCRIPT_DIR}/src/ffmpeg/config.h" "${PREBUILT_DIR}/arm64/include/" 2>/dev/null || true
  cp "${SCRIPT_DIR}/src/ffmpeg/config_components.h" "${PREBUILT_DIR}/arm64/include/" 2>/dev/null || true
fi

# Cleanup
rm -f "${TMP_ZIP}"

echo "✅ takefive-ffmpeg-kit: Prebuilt libraries installed to ${PREBUILT_DIR}/"
