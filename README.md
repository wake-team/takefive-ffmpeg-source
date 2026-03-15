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



---
Maintained by the **Wake Team** for the TakeFive Mobile App.
