#!/bin/sh

# SPDX-FileCopyrightText: 2025 eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

BUILD_DIR=$(realpath "$1")
DEPLOY_DIR="${BUILD_DIR}/deploy"
APPDIR="${BUILD_DIR}/deploy/AppDir"

mkdir -p "${DEPLOY_DIR}"
cd "${BUILD_DIR}"

# Install base files to AppDir
DESTDIR="${APPDIR}" ninja install

cd "${APPDIR}"

cat > eden.desktop << EOL
[Desktop Entry]
Type=Application
Name=Eden nightly
Icon=eden
StartupWMClass=eden
Exec=eden
Categories=Game;Emulator;
EOL

cp -v ./usr/share/icons/hicolor/scalable/apps/org.yuzu_emu.eden.svg ./eden.svg
ln -sfv ./eden.svg ./.DirIcon

# Bundle all libs
LIBDIR="/usr/lib"
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/bin/eden \
	$LIBDIR/lib*GL*.so* \
 	$LIBDIR/libSDL2*.so* \
  	$LIBDIR/libSDL3.so* \
	$LIBDIR/dri/* \
	$LIBDIR/vdpau/* \
	$LIBDIR/libvulkan* \
	$LIBDIR/libXss.so* \
	$LIBDIR/libdecor-0.so* \
	$LIBDIR/libgamemode.so* \
	$LIBDIR/qt6/plugins/audio/* \
	$LIBDIR/qt6/plugins/bearer/* \
	$LIBDIR/qt6/plugins/imageformats/* \
	$LIBDIR/qt6/plugins/iconengines/* \
	$LIBDIR/qt6/plugins/platforms/* \
	$LIBDIR/qt6/plugins/platformthemes/* \
	$LIBDIR/qt6/plugins/platforminputcontexts/* \
	$LIBDIR/qt6/plugins/styles/* \
	$LIBDIR/qt6/plugins/xcbglintegrations/* \
	$LIBDIR/qt6/plugins/wayland-*/* \
	$LIBDIR/pulseaudio/* \
	$LIBDIR/pipewire-0.3/* \
	$LIBDIR/spa-0.2/*/* \
	$LIBDIR/alsa-lib/*

wget https://github.com/VHSgunzo/sharun/releases/download/v0.6.3/sharun-x86_64 -O sharun
chmod a+x sharun

ln -fv ./sharun ./AppRun
./sharun -g
