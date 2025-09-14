#!/bin/bash

# FFmpeg Configuration Script with Dependency Detection
# This script automatically detects available codecs and configures FFmpeg accordingly

set -e

# Default values
FFMPEG_VERSION=${FFMPEG_VERSION:-"6.1"}
BUILD_TYPE=${BUILD_TYPE:-"release"}
PREFIX=${PREFIX:-"/usr/local"}
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=${ARCH:-$(uname -m)}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a library is available
check_library() {
    local lib_name=$1
    local pkg_name=${2:-$lib_name}
    
    if pkg-config --exists "$pkg_name" 2>/dev/null; then
        log "Found $lib_name"
        return 0
    else
        warn "$lib_name not found, skipping"
        return 1
    fi
}

# Function to check if a header file exists
check_header() {
    local header=$1
    local lib_name=$2
    
    if echo "#include <$header>" | gcc -E - >/dev/null 2>&1; then
        log "Found $lib_name"
        return 0
    else
        warn "$lib_name not found, skipping"
        return 1
    fi
}

# Function to check if codec is requested
is_codec_requested() {
    local codec=$1
    if [ -n "$ENABLE_CODECS" ]; then
        echo "$ENABLE_CODECS" | grep -q "$codec"
    else
        # If no specific codecs requested, enable common ones by default
        case $codec in
            libx264|libx265|libvpx|libfdk-aac|libmp3lame|libopus|libvorbis|libass|libfreetype|gnutls) return 0 ;;
            *) return 1 ;;
        esac
    fi
}

# Function to build configuration options
build_config() {
    local config_opts=""
    
    # Base configuration
    config_opts="--prefix=$PREFIX"
    config_opts="$config_opts --enable-gpl --enable-version3 --enable-nonfree"
    config_opts="$config_opts --enable-static --disable-shared"
    
    # Platform-specific options
    case $PLATFORM in
        darwin)
            config_opts="$config_opts --target-os=darwin"
            if [ "$ARCH" = "arm64" ]; then
                config_opts="$config_opts --arch=arm64 --enable-cross-compile"
            fi
            export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"
            ;;
        mingw*|msys*)
            config_opts="$config_opts --target-os=mingw32"
            config_opts="$config_opts --arch=$ARCH"
            config_opts="$config_opts --cross-prefix=$ARCH-w64-mingw32-"
            ;;
    esac
    
    # Video codecs
    if is_codec_requested "libx264" && check_library "x264" "x264"; then
        config_opts="$config_opts --enable-libx264"
    fi
    
    if is_codec_requested "libx265" && check_library "x265" "x265"; then
        config_opts="$config_opts --enable-libx265"
    fi
    
    if is_codec_requested "libvpx" && check_library "vpx" "vpx"; then
        config_opts="$config_opts --enable-libvpx"
    fi
    
    if is_codec_requested "libaom" && check_library "aom" "aom"; then
        config_opts="$config_opts --enable-libaom"
    fi
    
    if is_codec_requested "libsvtav1" && check_library "SvtAv1Enc" "SvtAv1Enc"; then
        config_opts="$config_opts --enable-libsvtav1"
    fi
    
    if is_codec_requested "libtheora" && check_library "theora" "theora"; then
        config_opts="$config_opts --enable-libtheora"
    fi
    
    # Audio codecs
    if is_codec_requested "libfdk-aac" && (check_library "fdk-aac" "fdk-aac" || check_library "libfdk-aac" "libfdk-aac"); then
        config_opts="$config_opts --enable-libfdk-aac"
    fi
    
    if is_codec_requested "libmp3lame" && (check_library "mp3lame" "lame" || check_header "lame/lame.h" "lame"); then
        config_opts="$config_opts --enable-libmp3lame"
    fi
    
    if is_codec_requested "libopus" && (check_library "opus" "opus" || check_library "libopus" "libopus"); then
        config_opts="$config_opts --enable-libopus"
    fi
    
    if is_codec_requested "libvorbis" && check_library "vorbis" "vorbis"; then
        config_opts="$config_opts --enable-libvorbis"
    fi
    
    # Other libraries
    if is_codec_requested "libass" && check_library "libass" "libass"; then
        config_opts="$config_opts --enable-libass"
    fi
    
    if is_codec_requested "libfreetype" && check_library "freetype2" "freetype2"; then
        config_opts="$config_opts --enable-libfreetype"
    fi
    
    if is_codec_requested "gnutls" && check_library "gnutls" "gnutls"; then
        config_opts="$config_opts --enable-gnutls"
    fi
    
    # SDL2 is optional and only needed for ffplay
    if check_library "sdl2" "sdl2"; then
        config_opts="$config_opts --enable-sdl2"
        log "SDL2 found - ffplay will be built"
    else
        warn "SDL2 not found - ffplay will not be built"
    fi
    
    if is_codec_requested "libwebp" && check_library "webp" "libwebp"; then
        config_opts="$config_opts --enable-libwebp"
    fi
    
    # Build type options
    if [ "$BUILD_TYPE" = "debug" ]; then
        config_opts="$config_opts --enable-debug --disable-optimizations --disable-stripping"
    else
        config_opts="$config_opts --enable-optimizations"
    fi
    
    # Platform-specific linking
    case $PLATFORM in
        linux)
            config_opts="$config_opts --extra-cflags=-static --extra-ldflags=-static"
            config_opts="$config_opts --pkg-config-flags=--static"
            ;;
        darwin)
            config_opts="$config_opts --extra-cflags=-mmacosx-version-min=10.15"
            config_opts="$config_opts --extra-ldflags=-mmacosx-version-min=10.15"
            ;;
        mingw*|msys*)
            config_opts="$config_opts --extra-cflags=-static --extra-ldflags=-static"
            ;;
    esac
    
    echo "$config_opts"
}

# Main execution
log "FFmpeg Configuration Script"
log "Platform: $PLATFORM ($ARCH)"
log "Build Type: $BUILD_TYPE"
log "Prefix: $PREFIX"

# Check if we're in the FFmpeg source directory
if [ ! -f "configure" ]; then
    error "Not in FFmpeg source directory. Please run this script from the FFmpeg source root."
    exit 1
fi

# Build configuration
CONFIG_OPTS=$(build_config)

log "Configuration options:"
echo "$CONFIG_OPTS" | tr ' ' '\n' | sed 's/^/  /'

# Run configure
log "Running FFmpeg configure..."
eval "./configure $CONFIG_OPTS"

if [ $? -eq 0 ]; then
    log "Configuration completed successfully!"
    log "Available codecs will be listed in the build output."
else
    error "Configuration failed. Check the output above for details."
    exit 1
fi