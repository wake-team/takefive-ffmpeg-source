require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "takefive-ffmpeg-kit"
  s.version      = package["version"]
  s.summary      = "TakeFive custom FFmpeg Kit for React Native — self-hosted prebuilt static libraries"
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platform          = :ios, '15.1'
  s.requires_arc      = true
  s.static_framework  = true

  s.source = { :git => "https://github.com/wake-team/takefive-ffmpeg-source.git", :tag => "v#{s.version}" }

  # Download prebuilt static libs from GitHub release (skipped if already present, e.g. local file: ref)
  s.prepare_command = <<-CMD
    if [ ! -d "takefive_prebuilt/arm64/include/libavutil" ]; then
      VERSION="#{s.version}"
      PREBUILT_URL="https://github.com/wake-team/takefive-ffmpeg-source/releases/download/v${VERSION}/takefive_prebuilt.tar.gz"
      echo "Downloading TakeFive prebuilt from ${PREBUILT_URL}..."
      curl -L "${PREBUILT_URL}" -o takefive_prebuilt.tar.gz
      tar -xzf takefive_prebuilt.tar.gz
      rm takefive_prebuilt.tar.gz
    else
      echo "Prebuilt libraries already present, skipping download."
    fi
  CMD

  s.dependency "React-Core"

  # ── Source files (all paths relative to podspec) ──
  s.source_files = [
    'react-native/ios/FFmpegKitReactNativeModule.h',
    'react-native/ios/FFmpegKitReactNativeModule.mm',
    'apple/src/*.h',
    'apple/src/*.m',
    'apple/src/fftools_*.c',
    'apple/src/fftools_*.h',
    # config.h must be listed here so CocoaPods adds it to own-target-headers.hmap
    # (searched at priority 2). Without this, the all-target-headers.hmap (priority 3)
    # resolves "config.h" to yoga's Config.h on macOS's case-insensitive filesystem,
    # which pulls in <bitset> and breaks pure C compilation units.
    'takefive_prebuilt/arm64/include/config.h',
  ]

  # Mark config.h as private (not exported) so it doesn't pollute the public API
  s.private_header_files = ['takefive_prebuilt/arm64/include/config.h']

  s.exclude_files = [
    'apple/src/ffmpeg.c',
    'apple/src/ffmpeg.h',
    'apple/src/ffmpeg_dec.c',
    'apple/src/ffmpeg_demux.c',
    'apple/src/ffmpeg_enc.c',
    'apple/src/ffmpeg_filter.c',
    'apple/src/ffmpeg_hw.c',
    'apple/src/ffmpeg_mux.c',
    'apple/src/ffmpeg_mux.h',
    'apple/src/ffmpeg_mux_init.c',
    'apple/src/ffmpeg_opt.c',
    'apple/src/ffmpeg_sched.c',
    'apple/src/ffmpeg_sched.h',
    'apple/src/ffmpeg_utils.h',
    'apple/src/ffprobe.c',
    'apple/src/ffplay.c',
    'apple/src/ffplay_renderer.c',
    'apple/src/ffplay_renderer.h',
    'apple/src/cmdutils.c',
    'apple/src/cmdutils.h',
    'apple/src/fopen_utf8.h',
    'apple/src/opt_common.c',
    'apple/src/opt_common.h',
    'apple/src/objpool.c',
    'apple/src/objpool.h',
    'apple/src/sync_queue.c',
    'apple/src/sync_queue.h',
    'apple/src/thread_queue.c',
    'apple/src/thread_queue.h',
    'apple/src/Makefile.*',
  ]

  s.public_header_files = [
    'apple/src/*.h',
    'react-native/ios/FFmpegKitReactNativeModule.h',
  ]

  # ── Prebuilt static libraries (relative paths) ──
  s.vendored_libraries = [
    'takefive_prebuilt/arm64/lib/libavcodec.a',
    'takefive_prebuilt/arm64/lib/libavdevice.a',
    'takefive_prebuilt/arm64/lib/libavfilter.a',
    'takefive_prebuilt/arm64/lib/libavformat.a',
    'takefive_prebuilt/arm64/lib/libavutil.a',
    'takefive_prebuilt/arm64/lib/libswresample.a',
    'takefive_prebuilt/arm64/lib/libswscale.a',
    'takefive_prebuilt/dependencies/libmp3lame/lib/libmp3lame.a',
    'takefive_prebuilt/dependencies/libopenh264/lib/libopenh264.a',
    'takefive_prebuilt/dependencies/libfreetype/lib/libfreetype.a',
  ]

  # ── Header search paths ──
  # IMPORTANT: takefive_prebuilt paths must come FIRST so that FFmpeg internal
  # headers (e.g. libavutil/thread.h) which do #include "config.h" find our
  # config.h (placed at takefive_prebuilt/arm64/include/config.h and
  # takefive_prebuilt/arm64/include/libavutil/config.h) before the compiler
  # accidentally resolves it to yoga's Config.h on macOS's case-insensitive FS.
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      '"${PODS_TARGET_SRCROOT}/takefive_prebuilt/arm64/include"',
      '"${PODS_TARGET_SRCROOT}/takefive_prebuilt/dependencies/libmp3lame/include"',
      '"${PODS_TARGET_SRCROOT}/takefive_prebuilt/dependencies/libopenh264/include"',
      '"${PODS_TARGET_SRCROOT}/takefive_prebuilt/dependencies/libfreetype/include"',
      '"${PODS_TARGET_SRCROOT}/apple/src"',
    ].join(' '),
    'OTHER_LDFLAGS' => '-ObjC -lz -lbz2 -liconv',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_LIB_CONFIG_H=0 FFMPEG_KIT_BUILD_DATE=20240101',
    # Disable Clang modules so C++ stdlib headers (<bitset> etc.)
    # resolve as textual includes when ObjC++ files pull in React/yoga headers.
    'CLANG_ENABLE_MODULES' => 'NO',
  }

  # ── System frameworks required by FFmpeg ──
  s.frameworks = [
    'AudioToolbox',
    'AVFoundation',
    'CoreMedia',
    'CoreVideo',
    'VideoToolbox',
    'Security',
    'CoreImage',
  ]

  s.libraries = ['z', 'bz2', 'iconv', 'c++']
end
