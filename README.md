# FFmpeg Multi-Platform Build System

This repository provides automated workflows and scripts to build FFmpeg for multiple platforms and architectures.

## Supported Platforms

- **Linux**: x86_64
- **macOS**: x86_64 (Intel) and arm64 (Apple Silicon)
- **Windows**: x86_64 (64-bit) and i686 (32-bit)

## Features

- **Robust Configuration**: Automatically detects available codecs and configures accordingly
- **Fallback Support**: Uses minimal configuration with built-in codecs if external libraries are missing
- **Static Builds**: Self-contained binaries with popular codecs included
- **GPL and Non-free Support**: Includes both open-source and proprietary codecs
- **Automated Workflows**: GitHub Actions for continuous integration
- **Cross-platform**: Linux, macOS, and Windows support
- **Customizable**: Choose specific codecs and build types
- **Debug Support**: Optional debug builds with symbols

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

# Test ffplay if it exists (requires SDL2)
if [ -f ./dist/linux-x86_64-release/ffplay ]; then
  ./dist/linux-x86_64-release/ffplay -version
fi

# Windows
.\dist\windows-x86_64-release\ffmpeg.exe -version
.\dist\windows-x86_64-release\ffprobe.exe -version

# Test ffplay if it exists
if (Test-Path ".\dist\windows-x86_64-release\ffplay.exe") {
  .\dist\windows-x86_64-release\ffplay.exe -version
}
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

1. **Missing dependencies**: The build system will automatically fall back to minimal configuration with built-in codecs
2. **Build failures**: Check the build logs for specific error messages
3. **Codec not found**: External codec libraries are optional - FFmpeg will build with available codecs
4. **libmp3lame not found**: Install `lame` development package or the build will use built-in AAC instead

### Codec Detection

The build system automatically detects available codec libraries:
- **Found**: Codec will be enabled in the build
- **Missing**: Codec will be skipped, build continues with available codecs
- **Fallback**: If too many codecs are missing, uses minimal configuration with built-in codecs

### FFplay Availability

FFplay (media player) requires SDL2 library:
- **SDL2 Found**: ffplay will be built and included
- **SDL2 Missing**: Only ffmpeg and ffprobe will be built
- **Note**: This is normal and doesn't affect core FFmpeg functionality

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