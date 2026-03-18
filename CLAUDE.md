# TakeFive FFmpeg Engine - AI Agent & LLM Context Rules

## Repository Purpose
This repository acts solely as a compilation engine for stripping, patching, and cross-compiling the upstream FFmpeg framework and its core LGPL-compatible dependencies (`LAME`, `OpenH264`) for integration into iOS and Android applications.

## AI Engineering Directives
When suggesting edits or making modifications to this repository:
1. **Zero-Tracking Source Rule**: NEVER commit any code from the `src/` directory. The `src/` directory represents dynamically cloned dependencies retrieved by `scripts/fetch_deps.sh`. Ensure any `.gitignore` file explicitly masks `src/*`.
2. **License Compliance (LGPL Priority)**: Strictly avoid enabling any GPL-only options in FFmpeg (like `x264` or `x265`). Modifying `build_takefive.sh` to drift from LGPL will critically violate the proprietary nature of the downstream mobile app.
3. **Freezing Workarounds**: Be aware that macOS Make execution of bash scripts (like `version.sh` and `pkgconfig_generate.sh` within FFmpeg) triggers `dyld` freezes via EndPoint Security. Do NOT delete `patch_ffmpeg.sh` from the build chain; it is fundamentally required to neutralize these scripts directly in the Actions pipeline.

## Build Scripts
- `build_takefive.sh`: The master compilation script overriding legacy build instructions.
- `scripts/fetch_deps.sh`: The dependency cloner. Re-fetches the latest FFmpeg tree, discarding local changes.

## Integrations
This code MUST NOT interact directly with mobile code logic. Its sole output is an offline iOS static archive (`.a`/`XCFramework`) or an Android `.AAR`. Refer users attempting integration to simply extract the precompiled Github Actions artifact generated here, rather than forcing them to sync this builder repository as a Git Submodule in the host project.
