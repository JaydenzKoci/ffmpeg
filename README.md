# FFmpeg Multi-Platform Build System

This repository provides automated workflows and scripts to build FFmpeg for multiple platforms and architectures.

## Supported Platforms

- **Linux**: x86_64
- **macOS**: x86_64 (Intel) and arm64 (Apple Silicon)
- **Windows**: x86_64 (64-bit) and i686 (32-bit)

## Features

- Static builds with popular codecs included
- GPL and non-free codec support
- Automated GitHub Actions workflows
- Local build scripts for development
- Customizable codec selection
- Debug and release build types

## Quick Start

### GitHub Actions (Automated)

The repository includes two main workflows:

1. **Standard Build** (`.github/workflows/build-ffmpeg.yml`)
   - Triggers on push to main/develop branches
   - Builds for all supported platforms
   - Creates releases automatically

2. **Custom Build** (`.github/workflows/build-custom-ffmpeg.yml`)
   - Manual trigger with customizable options
   - Choose FFmpeg version, codecs, and platforms
   - Debug or release builds

### Local Building

#### Prerequisites

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install build-essential yasm nasm pkg-config wget
```

**macOS:**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install yasm nasm pkg-config
```

**Windows:**
```powershell
# Install MSYS2 from https://www.msys2.org/
# Then in MSYS2 terminal (replace ARCH with x86_64 or i686):
pacman -S mingw-w64-ARCH-toolchain
pacman -S mingw-w64-ARCH-yasm mingw-w64-ARCH-nasm mingw-w64-ARCH-pkg-config
```

#### Build Commands

**Basic build:**
```bash
./scripts/build-ffmpeg.sh
```

**Custom build:**
```bash
./scripts/build-ffmpeg.sh --version 6.1 --type release --codecs "libx264,libx265,libvpx"
```

**Debug build:**
```bash
./scripts/build-ffmpeg.sh --type debug --jobs 8
```

**Windows builds:**
```powershell
# 64-bit build
.\scripts\build-ffmpeg.ps1 -Architecture "x86_64"

# 32-bit build
.\scripts\build-ffmpeg.ps1 -Architecture "i686"
```

## Configuration Options

### Included Codecs (Default)

- **Video**: libx264, libx265, libvpx
- **Audio**: libfdk-aac, libmp3lame, libopus, libvorbis
- **Subtitles**: libass
- **Other**: libfreetype, gnutls, libsdl2

### Optional Codecs

- libwebp (WebP image format)
- libaom (AV1 encoder)
- libsvtav1 (SVT-AV1 encoder)
- libtheora (Theora video)

## GitHub Actions Usage

### Triggering Builds

1. **Automatic**: Push to `main` or `develop` branch
2. **Manual**: Go to Actions → "Custom FFmpeg Build" → "Run workflow"

### Manual Workflow Options

- **FFmpeg Version**: Specify version (e.g., "6.1", "5.1.4")
- **Additional Codecs**: Comma-separated list (e.g., "libwebp,libaom,libsvtav1")
- **Build Type**: Choose "release" or "debug"
- **Platforms**: Select "all", "linux-only", "macos-only", or "windows-only"

### Artifacts

Built binaries are available as workflow artifacts:
- `ffmpeg-linux-x86_64`
- `ffmpeg-macos-x86_64`
- `ffmpeg-macos-arm64`
- `ffmpeg-windows-x86_64`
- `ffmpeg-windows-i686`

### Releases

Successful builds on the main branch automatically create releases with:
- Compressed archives for each platform
- SHA256 checksums
- Build information

## Build Script Options

```bash
./scripts/build-ffmpeg.sh [OPTIONS]

Options:
    -v, --version VERSION     FFmpeg version to build (default: 6.1)
    -t, --type TYPE          Build type: release|debug (default: release)
    -c, --codecs CODECS      Comma-separated list of codecs to enable
    -p, --prefix PREFIX      Installation prefix (default: /usr/local)
    -j, --jobs JOBS          Number of parallel jobs (auto-detected)
    -h, --help               Show help message
```

## Examples

### Building Specific Version
```bash
./scripts/build-ffmpeg.sh --version 5.1.4 --type release
```

### Custom Codec Selection
```bash
./scripts/build-ffmpeg.sh --codecs "libx264,libx265,libvpx,libaom"
```

### Debug Build with Custom Prefix
```bash
./scripts/build-ffmpeg.sh --type debug --prefix /opt/ffmpeg-debug
```

## Output Structure

```
dist/
├── linux-x86_64-release/
│   ├── ffmpeg
│   ├── ffprobe
│   ├── ffplay
│   └── build-info.txt
├── macos-x86_64-release/
│   └── ...
├── macos-arm64-release/
│   └── ...
├── windows-x86_64-release/
│   ├── ffmpeg.exe
│   ├── ffprobe.exe
│   ├── ffplay.exe
│   └── build-info.txt
└── windows-i686-release/
    └── ...
```

## Verification

Test your build:
```bash
# Linux/macOS
./dist/linux-x86_64-release/ffmpeg -version
./dist/linux-x86_64-release/ffprobe -version

# Windows
.\dist\windows-x86_64-release\ffmpeg.exe -version
.\dist\windows-x86_64-release\ffprobe.exe -version
```

Check available codecs:
```bash
# Linux/macOS
./dist/linux-x86_64-release/ffmpeg -codecs | grep -E "(libx264|libx265|libvpx)"

# Windows
.\dist\windows-x86_64-release\ffmpeg.exe -codecs | findstr "libx264 libx265 libvpx"
```

## Troubleshooting

### Common Issues

1. **Missing dependencies**: Run the dependency installation commands for your platform
2. **Build failures**: Check the build logs for specific error messages
3. **Codec not found**: Ensure the codec library is installed and properly configured

### Debug Information

Each build includes a `build-info.txt` file with:
- FFmpeg version
- Platform and architecture
- Build type and date
- Enabled codecs
- Configuration options used

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build process
5. Submit a pull request

## License

This build system is provided under the MIT License. Note that FFmpeg itself and various codec libraries may have different licensing terms (GPL, LGPL, etc.).

## Support

For issues with the build system, please open a GitHub issue with:
- Platform and architecture
- FFmpeg version
- Build command used
- Complete error output