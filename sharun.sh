#!/bin/sh

# SPDX-FileCopyrightText: 2025 eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

BUILD_DIR=$(realpath "$1")
cd "${BUILD_DIR}"

# Install eden
sudo ninja install

LIBDIR="/usr/lib"
COMMON_LIBS=(
    "$LIBDIR/libXss.so*"
    "$LIBDIR/libgamemode.so*"
    "$LIBDIR/qt6/plugins/audio/*"
    "$LIBDIR/qt6/plugins/bearer/*"
    "$LIBDIR/qt6/plugins/imageformats/*"
    "$LIBDIR/qt6/plugins/iconengines/*"
    "$LIBDIR/qt6/plugins/platforms/*"
    "$LIBDIR/qt6/plugins/platformthemes/*"
    "$LIBDIR/qt6/plugins/platforminputcontexts/*"
    "$LIBDIR/qt6/plugins/styles/*"
    "$LIBDIR/qt6/plugins/xcbglintegrations/*"
    "$LIBDIR/qt6/plugins/wayland-*/*"
    "$LIBDIR/pulseaudio/*"
    "$LIBDIR/spa-0.2/*/*"
    "$LIBDIR/alsa-lib/*"
)

MESA_EXTRA_LIBS=(
    "$LIBDIR/lib*GL*.so*"
    "$LIBDIR/dri/*"
    "$LIBDIR/vdpau/*"
    "$LIBDIR/libvulkan*"
    "$LIBDIR/libdecor-0.so*"
)

# Create a build function to handle two kinds of appimage
build_appimage() {
    local build_type="$1"
    local lib4bin_flags=("${!2}")
    local extra_libs=("${!3}")
    local appdir="./$build_type/AppDir"

    echo "=== Building $build_type AppImage ==="
    mkdir -p "$appdir"
    cd "$appdir"

    cp -v /usr/share/applications/eden.desktop ./eden.desktop
    cp -v /usr/share/icons/hicolor/scalable/apps/eden.svg ./eden.svg
    ln -sfv ./eden.svg ./.DirIcon

    wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
    chmod +x ./lib4bin

    ./lib4bin "${lib4bin_flags[@]}" \
        /usr/bin/eden \
        "${COMMON_LIBS[@]}" \
        "${extra_libs[@]}"

    ln -fv ./sharun ./AppRun
    ./sharun -g

    cd - > /dev/null
}

# set lib4bin flags
MESA_FLAGS=(-p -v -e -s -k)
LIGHT_FLAGS=(-p -v -s -k)

# Build Appimage with mesa drivers for maximum compatibility and possible latest fixes
build_appimage "mesa" MESA_FLAGS[@] MESA_EXTRA_LIBS[@]

# Build Appimage without mesa drivers for lightweight
EMPTY=()
build_appimage "light" LIGHT_FLAGS[@] EMPTY[@]
