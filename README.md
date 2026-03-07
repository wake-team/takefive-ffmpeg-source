# TakeFive FFmpeg Source (Wake Team)

This repository is an internally maintained fork of FFmpegKit, specifically optimized for the **TakeFive** mobile application. It contains the low-level C engine source and automated build scripts for iOS and Android.

## 🚀 Why we maintain this fork
- **Advanced Editing**: Support for `eq` (Color Grading), `colorbalance`, and `drawtext` (Watermarking).
- **Modern Targets**: Native support for iOS 15.1+ and Android SDK 26+.
- **Privacy Compliance**: Bundled with the Apple Privacy Manifest.
- **Reliability**: Hosted on our own infrastructure to ensure build stability and speed.

---

## 📱 Supported Platforms
- **iOS**: 15.1+ (arm64, x86_64, arm64-simulator)
- **Android**: API 26+ (arm-v7a, arm64-v8a, x86, x86-64)
- **React Native**: Via `takefive-ffmpeg` local module.
- **Flutter**: Supported via the internal bridge.

---

## 🛠️ Prerequisites (macOS)
To compile the native binaries, you need:
- **Xcode**: Latest version (supports iOS 17/18/26+ SDKs).
- **Homebrew Dependencies**:
  ```bash
  brew install autoconf automake libtool pkg-config
  ```
- **Android NDK**: Ensure `ANDROID_NDK_HOME` is set.

---

## 🔨 Build Instructions

### 1. Build for iOS (XCFrameworks)
This script generates the universal frameworks required for the TakeFive app.
```bash
./ios.sh -x --enable-gpl --enable-x264 --enable-fontconfig --enable-freetype --enable-fribidi --enable-lame --enable-libass --enable-openh264 --disable-armv7 --disable-armv7s --disable-arm64e --disable-i386 --disable-arm64-mac-catalyst --disable-x86-64-mac-catalyst --target=15.1
```

### 2. Build for Android (AAR)
```bash
./android.sh --enable-gpl --enable-x264 --enable-lame --enable-openh264 --api=26
```

---

## 📦 Distribution Workflow
Once the build completes:
1.  **Package**: Navigate to `prebuilt/apple-xcframework` and zip the `*.xcframework` folders.
2.  **Release**: Upload the zip to a [GitHub Release](https://github.com/wake-team/takefive-ffmpeg-source/releases).
3.  **Integrate**: Update the `DOWNLOAD_URL` in the `takeFive` repository's podspec.

For detailed maintenance steps, see the **[TakeFive Maintenance Guide](https://github.com/wake-team/takefive/blob/main/docs/MAINTAINING_MOBILE_FFMPEG.md)** in the main project.

---

## ⚖️ License
- This project is licensed under **GPL v3.0** due to the inclusion of the `x264` library.
- Based on the original FFmpegKit by Taner Sener.
