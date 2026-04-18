#!/bin/bash
set -e

# Configuration: Update these tags as needed
LAME_TAG="RELEASE__3_100"
OPENH264_TAG="v2.3.1"
LIBASS_TAG="0.17.1"
FRIBIDI_TAG="v1.0.13"
HARFBUZZ_TAG="8.0.1"
EXPAT_TAG="R_2_5_0"

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

# Fetch FFmpeg Main Repository
FFMPEG_TAG="n7.1"
fetch_lib "ffmpeg" "https://github.com/FFmpeg/FFmpeg" "${FFMPEG_TAG}"

# Fetch Core Dependencies (LGPL Compliant)
fetch_lib "lame" "https://github.com/arthenica/lame" "${LAME_TAG}"
fetch_lib "openh264" "https://github.com/arthenica/openh264" "${OPENH264_TAG}"
fetch_lib "libass" "https://github.com/arthenica/libass" "${LIBASS_TAG}"
# FreeType fetched as tarball (not git clone) to avoid Makefile submodule init failures
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
fetch_lib "fribidi" "https://github.com/fribidi/fribidi" "${FRIBIDI_TAG}" || fetch_lib "fribidi" "https://github.com/arthenica/fribidi" "${FRIBIDI_TAG}"
fetch_lib "harfbuzz" "https://github.com/harfbuzz/harfbuzz" "${HARFBUZZ_TAG}" || fetch_lib "harfbuzz" "https://github.com/arthenica/harfbuzz" "${HARFBUZZ_TAG}"
fetch_lib "expat" "https://github.com/libexpat/libexpat" "${EXPAT_TAG}" || fetch_lib "expat" "https://github.com/arthenica/libexpat" "${EXPAT_TAG}"

echo "✅ All dependencies fetched to ${SRC_DIR}"
