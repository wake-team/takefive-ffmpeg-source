require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

prebuilt_dir  = File.join(__dir__, 'takefive_prebuilt')
apple_src_dir = File.join(__dir__, 'apple', 'src')

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

  s.dependency "React-Core"

  # ── Source files ──
  # 1. React Native bridge (ObjC module)
  # 2. FFmpegKit ObjC wrapper layer (apple/src/*.h, *.m)
  # 3. FFmpegKit modified fftools C source (apple/src/fftools_*.c, fftools_*.h)
  #
  # We EXCLUDE the raw upstream ffmpeg CLI source files (ffmpeg.c, ffprobe.c,
  # ffplay.c, cmdutils.c, etc.) because the fftools_* versions are the patched
  # replacements used by ffmpeg-kit. We also exclude Makefile.* and ffplay_renderer
  # files since we don't use SDL/libplacebo.
  s.source_files = [
    'react-native/ios/FFmpegKitReactNativeModule.h',
    'react-native/ios/FFmpegKitReactNativeModule.m',
    "#{apple_src_dir}/*.h",
    "#{apple_src_dir}/*.m",
    "#{apple_src_dir}/fftools_*.c",
    "#{apple_src_dir}/fftools_*.h",
  ]

  s.exclude_files = [
    # Raw upstream FFmpeg CLI tools — conflict with fftools_* modified versions
    "#{apple_src_dir}/ffmpeg.c",
    "#{apple_src_dir}/ffmpeg.h",
    "#{apple_src_dir}/ffmpeg_dec.c",
    "#{apple_src_dir}/ffmpeg_demux.c",
    "#{apple_src_dir}/ffmpeg_enc.c",
    "#{apple_src_dir}/ffmpeg_filter.c",
    "#{apple_src_dir}/ffmpeg_hw.c",
    "#{apple_src_dir}/ffmpeg_mux.c",
    "#{apple_src_dir}/ffmpeg_mux.h",
    "#{apple_src_dir}/ffmpeg_mux_init.c",
    "#{apple_src_dir}/ffmpeg_opt.c",
    "#{apple_src_dir}/ffmpeg_sched.c",
    "#{apple_src_dir}/ffmpeg_sched.h",
    "#{apple_src_dir}/ffmpeg_utils.h",
    "#{apple_src_dir}/ffprobe.c",
    "#{apple_src_dir}/ffplay.c",
    "#{apple_src_dir}/ffplay_renderer.c",
    "#{apple_src_dir}/ffplay_renderer.h",
    "#{apple_src_dir}/cmdutils.c",
    "#{apple_src_dir}/cmdutils.h",
    "#{apple_src_dir}/fopen_utf8.h",
    "#{apple_src_dir}/opt_common.c",
    "#{apple_src_dir}/opt_common.h",
    "#{apple_src_dir}/objpool.c",
    "#{apple_src_dir}/objpool.h",
    "#{apple_src_dir}/sync_queue.c",
    "#{apple_src_dir}/sync_queue.h",
    "#{apple_src_dir}/thread_queue.c",
    "#{apple_src_dir}/thread_queue.h",
    # Build system files
    "#{apple_src_dir}/Makefile.*",
  ]

  s.public_header_files = [
    "#{apple_src_dir}/*.h",
    'react-native/ios/FFmpegKitReactNativeModule.h',
  ]

  # ── Prebuilt static libraries ──
  s.vendored_libraries = [
    # FFmpeg core
    File.join(prebuilt_dir, 'arm64', 'lib', 'libavcodec.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libavdevice.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libavfilter.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libavformat.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libavutil.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libswresample.a'),
    File.join(prebuilt_dir, 'arm64', 'lib', 'libswscale.a'),
    # Dependencies
    File.join(prebuilt_dir, 'dependencies', 'lame', 'lib', 'libmp3lame.a'),
    File.join(prebuilt_dir, 'dependencies', 'libopenh264', 'lib', 'libopenh264.a'),
  ]

  # ── Header search paths ──
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => [
      "\"#{File.join(prebuilt_dir, 'arm64', 'include')}\"",
      "\"#{File.join(prebuilt_dir, 'dependencies', 'lame', 'include')}\"",
      "\"#{File.join(prebuilt_dir, 'dependencies', 'libopenh264', 'include')}\"",
      "\"#{apple_src_dir}\"",
    ].join(' '),
    'OTHER_LDFLAGS' => '-ObjC -lz -lbz2 -liconv',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) HAVE_LIB_CONFIG_H=0',
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
