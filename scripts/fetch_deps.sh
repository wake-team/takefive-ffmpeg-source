#!/bin/bash
set -e

# Dependency versions — update here to upgrade
FFMPEG_TAG="n7.1"
OPENH264_TAG="v2.3.1"
HARFBUZZ_TAG="8.0.1"

BASEDIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${BASEDIR}/src"

echo "----------------------------------------------------------"
echo "🛠️  TakeFive FFmpeg Dependency Fetcher"
echo "----------------------------------------------------------"

fetch_lib() {
  local name=$1
  local url=$2
  local tag=$3
  local dest="${SRC_DIR}/${name}"

  echo "📦 Fetching ${name} (${tag})..."
  if [ -d "${dest}" ]; then
    echo "   Already exists, skipping clone..."
  else
    git clone --depth 1 --branch "${tag}" "${url}" "${dest}"
  fi
}

mkdir -p "${SRC_DIR}"

# FFmpeg (official upstream)
fetch_lib "ffmpeg" "https://github.com/FFmpeg/FFmpeg" "${FFMPEG_TAG}"

# LAME MP3 encoder (official SourceForge tarball — no authoritative GitHub mirror)
LAME_DIR="${SRC_DIR}/lame"
if [ ! -d "${LAME_DIR}" ]; then
  echo "📦 Fetching lame (tarball)..."
  curl -L "https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz" -o /tmp/lame.tar.gz
  mkdir -p "${LAME_DIR}"
  tar -xzf /tmp/lame.tar.gz -C "${LAME_DIR}" --strip-components=1
  rm /tmp/lame.tar.gz
else
  echo "   lame: Already exists, skipping..."
fi

# OpenH264 H.264 software codec (official Cisco upstream)
fetch_lib "openh264" "https://github.com/cisco/openh264" "${OPENH264_TAG}"

# HarfBuzz text shaping for drawtext filter (official upstream)
fetch_lib "harfbuzz" "https://github.com/harfbuzz/harfbuzz" "${HARFBUZZ_TAG}"

# FreeType font renderer for drawtext filter
# Fetched as tarball — git clone triggers submodule init failures in CI
FREETYPE_DIR="${SRC_DIR}/freetype"
if [ ! -d "${FREETYPE_DIR}" ]; then
  echo "📦 Fetching freetype (tarball)..."
  curl -L "https://download.savannah.gnu.org/releases/freetype/freetype-2.13.0.tar.gz" -o /tmp/freetype.tar.gz
  mkdir -p "${FREETYPE_DIR}"
  tar -xzf /tmp/freetype.tar.gz -C "${FREETYPE_DIR}" --strip-components=1
  rm /tmp/freetype.tar.gz
else
  echo "   freetype: Already exists, skipping..."
fi

echo "✅ All dependencies fetched to ${SRC_DIR}"
