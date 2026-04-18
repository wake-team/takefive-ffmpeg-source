cmake_minimum_required(VERSION 3.22.1)
project(ffmpegkit C)

# Repo root: android/ffmpeg-kit-android-lib/ → ../../
get_filename_component(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)

set(PREBUILT_DIR "${REPO_ROOT}/takefive_prebuilt_android/arm64-v8a")
set(DEPS_DIR     "${REPO_ROOT}/takefive_prebuilt_android/dependencies")
set(JNI_SRC_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp")

# ── Include paths ─────────────────────────────────────────────────────────────
include_directories(
    "${PREBUILT_DIR}/include"
    "${DEPS_DIR}/libmp3lame/include"
    "${DEPS_DIR}/libopenh264/include"
    "${DEPS_DIR}/libfreetype/include"
    "${JNI_SRC_DIR}"
)

# FFmpeg internal headers (thread.h, internal.h, etc.) — present in CI source tree
# Only add src/ffmpeg (NOT src/ffmpeg/libavutil) — adding libavutil directly
# causes libavutil/time.h to shadow the system <time.h>, breaking struct tm.
if(EXISTS "${REPO_ROOT}/src/ffmpeg/libavutil/thread.h")
    include_directories("${REPO_ROOT}/src/ffmpeg")
endif()

# ── Prebuilt static libraries ─────────────────────────────────────────────────
foreach(FFLIB avcodec avdevice avfilter avformat avutil swresample swscale)
    add_library(ff_${FFLIB} STATIC IMPORTED)
    set_target_properties(ff_${FFLIB} PROPERTIES
        IMPORTED_LOCATION "${PREBUILT_DIR}/lib/lib${FFLIB}.a")
endforeach()

add_library(ff_mp3lame STATIC IMPORTED)
set_target_properties(ff_mp3lame PROPERTIES
    IMPORTED_LOCATION "${DEPS_DIR}/libmp3lame/lib/libmp3lame.a")

add_library(ff_openh264 STATIC IMPORTED)
set_target_properties(ff_openh264 PROPERTIES
    IMPORTED_LOCATION "${DEPS_DIR}/libopenh264/lib/libopenh264.a")

add_library(ff_freetype STATIC IMPORTED)
set_target_properties(ff_freetype PROPERTIES
    IMPORTED_LOCATION "${DEPS_DIR}/libfreetype/lib/libfreetype.a")

add_library(ff_harfbuzz STATIC IMPORTED)
set_target_properties(ff_harfbuzz PROPERTIES
    IMPORTED_LOCATION "${DEPS_DIR}/libharfbuzz/lib/libharfbuzz.a")

# ── libffmpegkit_abidetect.so ─────────────────────────────────────────────────
add_library(ffmpegkit_abidetect SHARED
    "${JNI_SRC_DIR}/ffmpegkit_abidetect.c"
    "${CMAKE_ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c")
target_compile_definitions(ffmpegkit_abidetect PRIVATE FFMPEG_KIT_ARM64_V8A)
target_include_directories(ffmpegkit_abidetect PRIVATE
    "${CMAKE_ANDROID_NDK}/sources/android/cpufeatures")
target_link_libraries(ffmpegkit_abidetect log android)

# ── libffmpegkit.so — statically links all of FFmpeg + deps ──────────────────
add_library(ffmpegkit SHARED
    "${JNI_SRC_DIR}/ffmpegkit.c"
    "${JNI_SRC_DIR}/ffmpegkit_exception.c"
    "${JNI_SRC_DIR}/ffprobekit.c"
    "${JNI_SRC_DIR}/fftools_cmdutils.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_demux.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_filter.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_hw.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_mux.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_mux_init.c"
    "${JNI_SRC_DIR}/fftools_ffmpeg_opt.c"
    "${JNI_SRC_DIR}/fftools_ffprobe.c"
    "${JNI_SRC_DIR}/fftools_objpool.c"
    "${JNI_SRC_DIR}/fftools_opt_common.c"
    "${JNI_SRC_DIR}/fftools_sync_queue.c"
    "${JNI_SRC_DIR}/fftools_thread_queue.c"
)

target_compile_definitions(ffmpegkit PRIVATE
    FFMPEG_KIT_ARM64_V8A
    HAVE_LIB_CONFIG_H=0
    FFMPEG_KIT_BUILD_DATE=20260418
)

target_compile_options(ffmpegkit PRIVATE
    -Wall -Wno-unused-parameter -Wno-switch -Wno-sign-compare -Wno-deprecated-declarations
)

# --whole-archive pulls all symbols from the static libs so FFmpeg's internal
# cross-references resolve even when not directly called from the JNI layer.
target_link_libraries(ffmpegkit
    -Wl,--allow-multiple-definition
    -Wl,--whole-archive
    ff_avfilter ff_avformat ff_avcodec ff_avutil ff_swresample ff_swscale ff_avdevice
    ff_mp3lame ff_openh264 ff_freetype ff_harfbuzz
    -Wl,--no-whole-archive
    log z android mediandk c++_shared
)
