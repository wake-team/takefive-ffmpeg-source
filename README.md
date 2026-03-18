# TakeFive FFmpeg Engine (Mobile Optimized)

[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![Build Status](https://github.com/wake-team/takefive-ffmpeg-source/actions/workflows/build.yml/badge.svg)](https://github.com/wake-team/takefive-ffmpeg-source/actions)

An optimized FFmpeg build system for iOS and Android, specifically engineered for the **TakeFive** video processing pipeline. This repository is a specialized fork of FFmpegKit, migrating towards **FFmpeg 7.1** with a focus on LGPL compliance and hardware acceleration.

## 🌟 Key Features

- **FFmpeg 7.1 Core:** Leveraging the latest video processing improvements.
- **Hardware Acceleration:** Native support for Apple **VideoToolbox** (iOS) and Android **MediaCodec**.
- **Commercial Friendly:** Strictly configured for **LGPL v3.0**. GPL/Non-free components are disabled to ensure compatibility with private commercial applications.
- **Architecture Optimized:** Focused on `arm64` (physical devices) and `arm64-simulator` (Apple Silicon development).
- **Consolidated Dependencies:** Includes patched versions of `libass`, `freetype`, `fribidi`, `lame`, and `openh264`.

## 🚀 Build System

This project uses a cloud-first build strategy via **GitHub Actions** to bypass local environment inconsistencies (like macOS Gatekeeper/SIP).

### Artifacts Produced:
- **iOS:** Universal XCFrameworks (`arm64` + `arm64-simulator`).
- **Android:** Android Archive (AAR) with support for API Level 26+.

### Local Compilation:
To build locally (macOS recommended for iOS):
```bash
./ios.sh -x --enable-ios-videotoolbox --enable-ios-avfoundation
./android.sh --api-level=26
```

## ⚖️ License & Compliance

This engine is licensed under the **GNU Lesser General Public License (LGPL) version 3.0**. 

**Important for Developers:**
- This build **DOES NOT** include GPL-licensed libraries (like `x264` or `x265`).
- You can safely link this library into your private commercial applications without being required to open-source your app's proprietary code.
- We have implemented strict build-time checks to prevent accidental GPL enablement.

## 🛠 Internal Patches

1.  **Modern CMake:** Forced minimum CMake 3.5+ for sub-modules to support modern CI environments.
2.  **Apple Silicon Fixes:** Patched `lame` and other assembly-heavy dependencies for stable iOS simulator builds on M1/M2/M3 chips.
3.  **Dependency Isolation:** Scripts use a local `src/` directory to ensure build reproducibility.

## 📦 Integration

Compiled binaries are available in the [GitHub Actions Release Tab](https://github.com/wake-team/takefive-ffmpeg-source/actions).

### How to use this in your Mobile App Building Process

Because this engine creates pure, precompiled static libraries (e.g., `libavcodec.a`, `libavformat.a`) rather than relying on on-the-fly source builds, your mobile application build pipeline remains incredibly fast and immune to C-compiler breaks.

#### iOS Integration (Xcode / React Native iOS)
1. **Download the Artifact**: Navigate to the latest successful GitHub Action run and download the `takefive-ffmpeg-ios-arm64.zip` artifact.
2. **Extract**: Unzip the folder to reveal the `lib/` (static `.a` files) and `include/` (C headers) directories.
3. **Import to Xcode**: Drag and drop the `lib` folder completely into your Xcode project's *Frameworks, Libraries, and Embedded Content* section. 
4. **Header Search Paths**: In your Xcode Build Settings, add the path to the extracted `include/` folder to the **Header Search Paths** (`HEADER_SEARCH_PATHS`) setting so your Objective-C or Swift Bridging Headers can locate `<libavutil/avutil.h>`, etc.
5. **Link Dependencies**: Ensure you dynamically link the `VideoToolbox.framework`, `AudioToolbox.framework`, `CoreMedia.framework`, and `AVFoundation.framework` in Xcode, as FFmpeg relies on these Apple-native libraries for hardware acceleration.
6. **Done**: You can now import FFmpeg headers and invoke its C-API directly within your iOS app bundle.

#### Android Integration (JNI / NDK)
1. **Download the Artifact**: Navigate to the latest successful GitHub Action run and download the generated Android `.zip` or `.aar` artifact containing the compiled `.so` (shared) or `.a` (static) binary files for `arm64-v8a` and `armeabi-v7a`.
2. **JNI / CMakeLists**: Move the extracted C headers (`include/`) and library files (`lib/`) into your Android project's `app/src/main/cpp` directory or equivalent natively mounted folder.
3. **Link Libraries**: In your Android `CMakeLists.txt`, set up the prebuilt libraries for CMake using `add_library(avcodec STATIC IMPORTED)` and point their properties utilizing `set_target_properties(avcodec PROPERTIES IMPORTED_LOCATION ...)`. Do this for all downloaded FFmpeg core structures.
4. **Android Media Framework**: Link the requisite NDK acceleration API tools like `libmediandk.so` in `target_link_libraries` so FFmpeg can decode natively on Android silicon.
5. **Java/Kotlin Invoke**: Craft your own local JNI wrappers in C++ (`native()` functions) to interface with the extracted headers within your Android environment!



---
Maintained by the **Wake Team** for the TakeFive Mobile App.
