#!/bin/bash

# Minimal FFmpeg Configuration Script
# This script configures FFmpeg with only built-in codecs when external libraries are missing

set -e

# Default values
FFMPEG_VERSION=${FFMPEG_VERSION:-"6.1"}
BUILD_TYPE=${BUILD_TYPE:-"release"}
PREFIX=${PREFIX:-"/usr/local"}
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=${ARCH:-$(uname -m)}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log "FFmpeg Minimal Configuration Script"
log "Platform: $PLATFORM ($ARCH)"
log "Build Type: $BUILD_TYPE"
log "Prefix: $PREFIX"

# Check if we're in the FFmpeg source directory
if [ ! -f "configure" ]; then
    echo "Error: Not in FFmpeg source directory"
    exit 1
fi

# Build minimal configuration with built-in codecs only
CONFIG_OPTS="--prefix=$PREFIX"
CONFIG_OPTS="$CONFIG_OPTS --enable-gpl --enable-version3"
CONFIG_OPTS="$CONFIG_OPTS --enable-static --disable-shared"

# Platform-specific options
case $PLATFORM in
    darwin)
        CONFIG_OPTS="$CONFIG_OPTS --target-os=darwin"
        if [ "$ARCH" = "arm64" ]; then
            CONFIG_OPTS="$CONFIG_OPTS --arch=arm64 --enable-cross-compile"
        fi
        CONFIG_OPTS="$CONFIG_OPTS --extra-cflags=-mmacosx-version-min=10.15"
        CONFIG_OPTS="$CONFIG_OPTS --extra-ldflags=-mmacosx-version-min=10.15"
        ;;
    mingw*|msys*)
        CONFIG_OPTS="$CONFIG_OPTS --target-os=mingw32"
        CONFIG_OPTS="$CONFIG_OPTS --arch=$ARCH"
        CONFIG_OPTS="$CONFIG_OPTS --cross-prefix=$ARCH-w64-mingw32-"
        CONFIG_OPTS="$CONFIG_OPTS --extra-cflags=-static --extra-ldflags=-static"
        ;;
    linux)
        CONFIG_OPTS="$CONFIG_OPTS --extra-cflags=-static --extra-ldflags=-static"
        CONFIG_OPTS="$CONFIG_OPTS --pkg-config-flags=--static"
        ;;
esac

# Build type options
if [ "$BUILD_TYPE" = "debug" ]; then
    CONFIG_OPTS="$CONFIG_OPTS --enable-debug --disable-optimizations --disable-stripping"
else
    CONFIG_OPTS="$CONFIG_OPTS --enable-optimizations"
fi

warn "Using minimal configuration with built-in codecs only"
warn "ffplay will not be built (requires SDL2)"
log "Configuration options:"
echo "$CONFIG_OPTS" | tr ' ' '\n' | sed 's/^/  /'

# Run configure
log "Running FFmpeg configure..."
eval "./configure $CONFIG_OPTS"

if [ $? -eq 0 ]; then
    log "Minimal configuration completed successfully!"
    warn "Note: External codec libraries were not found or not requested"
    warn "The build will include only built-in codecs (H.264, AAC, etc.)"
else
    echo "Error: Configuration failed"
    exit 1
fi