#!/bin/bash

# FFmpeg Build Script
# Supports Linux and macOS builds with customizable options

set -e

# Default configuration
FFMPEG_VERSION="6.1"
BUILD_TYPE="release"
PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
ENABLE_CODECS="libx264,libx265,libvpx,libfdk-aac,libmp3lame,libopus"
PREFIX="/usr/local"
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -v, --version VERSION     FFmpeg version to build (default: $FFMPEG_VERSION)
    -t, --type TYPE          Build type: release|debug (default: $BUILD_TYPE)
    -c, --codecs CODECS      Comma-separated list of codecs to enable
    -p, --prefix PREFIX      Installation prefix (default: $PREFIX)
    -j, --jobs JOBS          Number of parallel jobs (default: $JOBS)
    -h, --help               Show this help message

Examples:
    $0 --version 6.1 --type release
    $0 --codecs "libx264,libx265,libvpx" --jobs 8
    $0 --type debug --prefix /opt/ffmpeg
EOF
}

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

install_dependencies() {
    log "Installing dependencies for $PLATFORM..."
    
    case $PLATFORM in
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y \
                    build-essential \
                    yasm \
                    nasm \
                    pkg-config \
                    libx264-dev \
                    libx265-dev \
                    libvpx-dev \
                    libfdk-aac-dev \
                    libmp3lame-dev \
                    libopus-dev \
                    libvorbis-dev \
                    libtheora-dev \
                    libass-dev \
                    libfreetype6-dev \
                    libgnutls28-dev \
                    libsdl2-dev
            elif command -v yum >/dev/null 2>&1; then
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y \
                    yasm \
                    nasm \
                    pkgconfig \
                    x264-devel \
                    x265-devel \
                    libvpx-devel \
                    fdk-aac-devel \
                    lame-devel \
                    opus-devel \
                    libvorbis-devel \
                    libtheora-devel \
                    libass-devel \
                    freetype-devel \
                    gnutls-devel \
                    SDL2-devel
            else
                error "Unsupported Linux distribution"
            fi
            ;;
        darwin)
            if ! command -v brew >/dev/null 2>&1; then
                error "Homebrew is required on macOS"
            fi
            brew install \
                yasm \
                nasm \
                pkg-config \
                x264 \
                x265 \
                libvpx \
                fdk-aac \
                lame \
                opus \
                libvorbis \
                theora \
                libass \
                freetype \
                gnutls \
                sdl2
            ;;
        *)
            error "Unsupported platform: $PLATFORM"
            ;;
    esac
}

download_ffmpeg() {
    log "Downloading FFmpeg $FFMPEG_VERSION..."
    
    if [ ! -f "ffmpeg-$FFMPEG_VERSION.tar.xz" ]; then
        wget "https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.xz"
    fi
    
    if [ -d "ffmpeg-$FFMPEG_VERSION" ]; then
        rm -rf "ffmpeg-$FFMPEG_VERSION"
    fi
    
    tar -xf "ffmpeg-$FFMPEG_VERSION.tar.xz"
}

configure_ffmpeg() {
    log "Configuring FFmpeg..."
    
    cd "ffmpeg-$FFMPEG_VERSION"
    
    # Export environment variables for the configuration script
    export FFMPEG_VERSION
    export BUILD_TYPE
    export PREFIX
    export PLATFORM
    export ARCH
    export ENABLE_CODECS
    
    # Use the robust configuration script, fall back to minimal if it fails
    chmod +x ../scripts/configure-ffmpeg.sh
    chmod +x ../scripts/configure-minimal.sh
    
    if ! ../scripts/configure-ffmpeg.sh; then
        warn "Robust configuration failed, trying minimal configuration..."
        ../scripts/configure-minimal.sh
    fi
}

build_ffmpeg() {
    log "Building FFmpeg with $JOBS parallel jobs..."
    make -j$JOBS
}

create_distribution() {
    log "Creating distribution..."
    
    DIST_DIR="../dist/$PLATFORM-$ARCH-$BUILD_TYPE"
    mkdir -p "$DIST_DIR"
    
    cp ffmpeg "$DIST_DIR/"
    cp ffprobe "$DIST_DIR/"
    [ -f ffplay ] && cp ffplay "$DIST_DIR/"
    
    if [ "$BUILD_TYPE" = "release" ]; then
        strip "$DIST_DIR"/*
    fi
    
    # Create version info
    cat > "$DIST_DIR/build-info.txt" << EOF
FFmpeg Build Information
========================
Version: $FFMPEG_VERSION
Platform: $PLATFORM
Architecture: $ARCH
Build Type: $BUILD_TYPE
Codecs: $ENABLE_CODECS
Build Date: $(date)
EOF
    
    log "Distribution created in $DIST_DIR"
}

test_build() {
    log "Testing build..."
    
    DIST_DIR="../dist/$PLATFORM-$ARCH-$BUILD_TYPE"
    
    "$DIST_DIR/ffmpeg" -version | head -1
    "$DIST_DIR/ffprobe" -version | head -1
    
    log "Build test completed successfully"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            FFMPEG_VERSION="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -c|--codecs)
            ENABLE_CODECS="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate build type
if [[ "$BUILD_TYPE" != "release" && "$BUILD_TYPE" != "debug" ]]; then
    error "Invalid build type: $BUILD_TYPE (must be 'release' or 'debug')"
fi

# Main build process
log "Starting FFmpeg build process..."
log "Version: $FFMPEG_VERSION"
log "Platform: $PLATFORM ($ARCH)"
log "Build Type: $BUILD_TYPE"
log "Codecs: $ENABLE_CODECS"

install_dependencies
download_ffmpeg
configure_ffmpeg
build_ffmpeg
create_distribution
test_build

log "FFmpeg build completed successfully!"
log "Binaries available in: dist/$PLATFORM-$ARCH-$BUILD_TYPE/"