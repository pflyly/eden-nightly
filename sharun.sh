#!/bin/bash

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

# Set base libs
COMMON_LIBS=(
    /usr/lib/libSDL*
    /usr/lib/libXss.so*
    /usr/lib/libgamemode.so*
    /usr/lib/qt6/plugins/audio/*
    /usr/lib/qt6/plugins/bearer/*
    /usr/lib/qt6/plugins/imageformats/*
    /usr/lib/qt6/plugins/iconengines/*
    /usr/lib/qt6/plugins/platforms/*
    /usr/lib/qt6/plugins/platformthemes/*
    /usr/lib/qt6/plugins/platforminputcontexts/*
    /usr/lib/qt6/plugins/styles/*
    /usr/lib/qt6/plugins/xcbglintegrations/*
    /usr/lib/qt6/plugins/wayland-*/*
    /usr/lib/pulseaudio/*
    /usr/lib/spa-0.2/*/*
    /usr/lib/alsa-lib/*
)

# Set mesa related libs
MESA_EXTRA_LIBS=(
    /usr/lib/lib*GL*.so*
    /usr/lib/dri/*
    /usr/lib/vdpau/*
    /usr/lib/libvulkan*
    /usr/lib/libdecor-0.so*
)
EMPTY=()

# Set lib4bin flags
MESA_FLAGS=(-p -v -e -s -k)
LIGHT_FLAGS=(-p -v -s -k)

# Create a genarate function to handle two kinds of appdir
genarate_appdir() {
    local build_type="$1"
    local lib4bin_flags=("${!2}")
    local extra_libs=("${!3}")
    local appdir="./$build_type/AppDir"

    echo "=== Genarating $build_type Appdir ==="
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

# Genarate Appdir with mesa drivers for maximum compatibility and possible latest fixes for some games
genarate_appdir "mesa" MESA_FLAGS[@] MESA_EXTRA_LIBS[@]

# Genarate Appdir without mesa drivers for lightweight
# genarate_appdir "light" LIGHT_FLAGS[@] EMPTY[@]
