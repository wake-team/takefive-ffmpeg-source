# TakeFive FFmpeg Source (Wake Team)

This repository is an internally maintained fork of FFmpegKit, optimized for the **TakeFive** mobile application.

## 🚀 Build Strategy: Cloud-First
Due to macOS security policies (Gatekeeper) that can interfere with local compilation, we primarily use **GitHub Actions** for building binaries.

- **iOS**: Builds Universal XCFrameworks (arm64 + arm64-simulator).
- **Android**: Builds AAR packages (targeting API 26+).
- **Automation**: Every push to \`main\` triggers a full cross-platform build.

## ⚖️ License Compliance
This project is configured in **LGPL mode**.
- **NO** \`--enable-gpl\` or \`--enable-nonfree\` flags.
- Uses Apple **VideoToolbox** for hardware acceleration (LGPL compliant).
- Ensures the TakeFive App commercial source code remains private.

## 🛠️ Internal Patches
We have applied the following fixes to ensure modern compatibility:
1.  **CMake 3.5+**: Forced minimum CMake version across \`libpng\`, \`freetype\`, and \`expat\` to support modern CI runners.
2.  **Lame arm64-ios**: Patched build scripts to support Apple Silicon architectures.
3.  **Cross-Compilation**: Enhanced \`configure\` calls to properly handle iOS simulator targets.

## 📦 Distribution
Binary artifacts are available in the [GitHub Actions tab](https://github.com/wake-team/takefive-ffmpeg-source/actions). For integration steps, see the **[TakeFive Maintenance Guide](https://github.com/wake-team/takefive/blob/main/docs/MAINTAINING_MOBILE_FFMPEG.md)** in the main project.
