# FFmpeg Build Script for Windows
# Requires MSYS2/MinGW-w64 environment

param(
    [string]$Version = "6.1",
    [ValidateSet("release", "debug")]
    [string]$BuildType = "release",
    [string]$Codecs = "libx264,libx265,libvpx,libfdk-aac,libmp3lame,libopus",
    [string]$Prefix = "C:\ffmpeg",
    [int]$Jobs = $env:NUMBER_OF_PROCESSORS,
    [switch]$Help
)

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARN] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
    exit 1
}

function Show-Help {
    @"
FFmpeg Build Script for Windows

Usage: .\build-ffmpeg.ps1 [OPTIONS]

Parameters:
    -Version VERSION      FFmpeg version to build (default: $Version)
    -BuildType TYPE       Build type: release|debug (default: $BuildType)
    -Codecs CODECS        Comma-separated list of codecs to enable
    -Prefix PREFIX        Installation prefix (default: $Prefix)
    -Jobs JOBS            Number of parallel jobs (default: $Jobs)
    -Help                 Show this help message

Examples:
    .\build-ffmpeg.ps1 -Version "6.1" -BuildType "release"
    .\build-ffmpeg.ps1 -Codecs "libx264,libx265,libvpx" -Jobs 8
    .\build-ffmpeg.ps1 -BuildType "debug" -Prefix "C:\ffmpeg-debug"

Requirements:
    - MSYS2 with MinGW-w64 toolchain
    - Git for Windows
    - Internet connection for downloading dependencies

Setup MSYS2:
    1. Download and install MSYS2 from https://www.msys2.org/
    2. Open MSYS2 terminal and run:
       pacman -S mingw-w64-x86_64-toolchain
       pacman -S mingw-w64-x86_64-yasm
       pacman -S mingw-w64-x86_64-nasm
       pacman -S mingw-w64-x86_64-pkg-config
       pacman -S mingw-w64-x86_64-x264
       pacman -S mingw-w64-x86_64-x265
       pacman -S mingw-w64-x86_64-libvpx
"@
}

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if we're in a MinGW environment
    if (-not $env:MINGW_PREFIX) {
        Write-Error "This script must be run in a MinGW-w64 environment (MSYS2)"
    }
    
    # Check for required tools
    $requiredTools = @("gcc", "make", "yasm", "nasm", "pkg-config")
    foreach ($tool in $requiredTools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Error "Required tool not found: $tool"
        }
    }
    
    Write-Info "Prerequisites check passed"
}

function Install-Dependencies {
    Write-Info "Installing dependencies via pacman..."
    
    $packages = @(
        "mingw-w64-x86_64-x264",
        "mingw-w64-x86_64-x265", 
        "mingw-w64-x86_64-libvpx",
        "mingw-w64-x86_64-fdk-aac",
        "mingw-w64-x86_64-lame",
        "mingw-w64-x86_64-libopus",
        "mingw-w64-x86_64-libvorbis",
        "mingw-w64-x86_64-libtheora",
        "mingw-w64-x86_64-libass",
        "mingw-w64-x86_64-freetype",
        "mingw-w64-x86_64-gnutls",
        "mingw-w64-x86_64-SDL2"
    )
    
    foreach ($package in $packages) {
        Write-Info "Installing $package..."
        & pacman -S --noconfirm $package
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to install $package, continuing..."
        }
    }
}

function Download-FFmpeg {
    Write-Info "Downloading FFmpeg $Version..."
    
    $url = "https://ffmpeg.org/releases/ffmpeg-$Version.tar.xz"
    $archive = "ffmpeg-$Version.tar.xz"
    $extractDir = "ffmpeg-$Version"
    
    if (Test-Path $archive) {
        Write-Info "Archive already exists, skipping download"
    } else {
        try {
            Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
        } catch {
            Write-Error "Failed to download FFmpeg: $_"
        }
    }
    
    if (Test-Path $extractDir) {
        Write-Info "Removing existing source directory..."
        Remove-Item -Recurse -Force $extractDir
    }
    
    Write-Info "Extracting archive..."
    & tar -xf $archive
    
    if (-not (Test-Path $extractDir)) {
        Write-Error "Failed to extract FFmpeg source"
    }
}

function Configure-FFmpeg {
    Write-Info "Configuring FFmpeg..."
    
    Set-Location "ffmpeg-$Version"
    
    # Base configuration
    $configOpts = @(
        "--prefix=$Prefix",
        "--enable-gpl",
        "--enable-version3", 
        "--enable-nonfree",
        "--enable-static",
        "--disable-shared",
        "--target-os=mingw32",
        "--arch=x86_64",
        "--cross-prefix=x86_64-w64-mingw32-"
    )
    
    # Add codec options
    $codecList = $Codecs -split ","
    foreach ($codec in $codecList) {
        $codec = $codec.Trim()
        switch ($codec) {
            "libx264" { $configOpts += "--enable-libx264" }
            "libx265" { $configOpts += "--enable-libx265" }
            "libvpx" { $configOpts += "--enable-libvpx" }
            "libfdk-aac" { $configOpts += "--enable-libfdk-aac" }
            "libmp3lame" { $configOpts += "--enable-libmp3lame" }
            "libopus" { $configOpts += "--enable-libopus" }
            "libvorbis" { $configOpts += "--enable-libvorbis" }
            "libtheora" { $configOpts += "--enable-libtheora" }
            "libass" { $configOpts += "--enable-libass" }
            "libfreetype" { $configOpts += "--enable-libfreetype" }
            "gnutls" { $configOpts += "--enable-gnutls" }
            "libsdl2" { $configOpts += "--enable-libsdl2" }
            default { Write-Warning "Unknown codec: $codec" }
        }
    }
    
    # Build type options
    if ($BuildType -eq "debug") {
        $configOpts += @("--enable-debug", "--disable-optimizations", "--disable-stripping")
    } else {
        $configOpts += "--enable-optimizations"
    }
    
    Write-Info "Configuration options: $($configOpts -join ' ')"
    
    & ./configure @configOpts
    if ($LASTEXITCODE -ne 0) {
        Write-Error "FFmpeg configuration failed"
    }
}

function Build-FFmpeg {
    Write-Info "Building FFmpeg with $Jobs parallel jobs..."
    
    & make -j$Jobs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "FFmpeg build failed"
    }
}

function Create-Distribution {
    Write-Info "Creating distribution..."
    
    $distDir = "..\dist\windows-x86_64-$BuildType"
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    
    # Copy binaries
    Copy-Item "ffmpeg.exe" "$distDir\"
    Copy-Item "ffprobe.exe" "$distDir\"
    if (Test-Path "ffplay.exe") {
        Copy-Item "ffplay.exe" "$distDir\"
    }
    
    # Strip binaries for release builds
    if ($BuildType -eq "release") {
        Write-Info "Stripping binaries..."
        & strip "$distDir\ffmpeg.exe"
        & strip "$distDir\ffprobe.exe"
        if (Test-Path "$distDir\ffplay.exe") {
            & strip "$distDir\ffplay.exe"
        }
    }
    
    # Create build info
    $buildInfo = @"
FFmpeg Build Information
========================
Version: $Version
Platform: Windows
Architecture: x86_64
Build Type: $BuildType
Codecs: $Codecs
Build Date: $(Get-Date)
"@
    
    $buildInfo | Out-File "$distDir\build-info.txt" -Encoding UTF8
    
    Write-Info "Distribution created in $distDir"
}

function Test-Build {
    Write-Info "Testing build..."
    
    $distDir = "..\dist\windows-x86_64-$BuildType"
    
    & "$distDir\ffmpeg.exe" -version | Select-Object -First 1
    & "$distDir\ffprobe.exe" -version | Select-Object -First 1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Build test completed successfully"
    } else {
        Write-Error "Build test failed"
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

# Validate build type
if ($BuildType -notin @("release", "debug")) {
    Write-Error "Invalid build type: $BuildType (must be 'release' or 'debug')"
}

Write-Info "Starting FFmpeg build process..."
Write-Info "Version: $Version"
Write-Info "Platform: Windows (x86_64)"
Write-Info "Build Type: $BuildType"
Write-Info "Codecs: $Codecs"

try {
    Test-Prerequisites
    Install-Dependencies
    Download-FFmpeg
    Configure-FFmpeg
    Build-FFmpeg
    Create-Distribution
    Test-Build
    
    Write-Info "FFmpeg build completed successfully!"
    Write-Info "Binaries available in: dist\windows-x86_64-$BuildType\"
} catch {
    Write-Error "Build process failed: $_"
} finally {
    # Return to original directory
    if (Test-Path "ffmpeg-$Version") {
        Set-Location ..
    }
}