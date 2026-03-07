# TakeFive FFmpeg Source (Wake Team) - LGPL Edition

This repository is an internally maintained fork of FFmpegKit, optimized for **TakeFive**. 

## ⚖️ License Compliance (IMPORTANT)
To protect the TakeFive App commercial source code, this build is configured in **LGPL mode**. 
- **NO** \`--enable-gpl\` or \`--enable-nonfree\` flags are used.
- **NO** \`x264\`, \`x265\`, or \`libxvid\` libraries are included.
- We use Apple **VideoToolbox** (Hardware Acceleration) for H.264 encoding, which is LGPL compliant.

---

## 🔨 Build Instructions (LGPL Safe)

### 1. Build for iOS (XCFrameworks)
\`\`\`bash
./ios.sh -x --enable-ios-videotoolbox --enable-ios-avfoundation --enable-fontconfig --enable-freetype --enable-fribidi --enable-libass --enable-openh264 --disable-armv7 --disable-armv7s --disable-arm64e --disable-i386 --disable-arm64-mac-catalyst --disable-x86-64-mac-catalyst --target=15.1
\`\`\`

### 2. Build for Android (AAR)
\`\`\`bash
./android.sh --enable-openh264 --api=26
\`\`\`

---

## 📦 Distribution
Follow the distribution workflow in the [TakeFive Maintenance Guide](https://github.com/wake-team/takefive/blob/main/docs/MAINTAINING_MOBILE_FFMPEG.md).
