#!/bin/sh

# SPDX-FileCopyrightText: 2025 eden Emulator Project
# SPDX-License-Identifier: GPL-3.0-or-later

# This script assumes you're in the source directory
set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export BASE_ARCH="$(uname -m)"
export ARCH="$BASE_ARCH"

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

# NOW MAKE APPIMAGE
mkdir -p ./AppDir
cd ./AppDir

cat > eden.desktop << EOL
[Desktop Entry]
Type=Application
Name=Eden
Icon=eden
StartupWMClass=eden
Exec=eden
Categories=Game;Emulator;
EOL

cp ../dist/eden.svg ./eden.svg

ln -sf ./eden.svg ./.DirIcon

if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=Eden|Name=Eden Nightly|' ./eden.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

LIBDIR="/usr/lib"
# some distros are weird and use a subdir

if [ ! -f "/usr/lib/libGL.so" ]
then
    LIBDIR="/usr/lib/${BASE_ARCH}-linux-gnu"
fi

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	../build/bin/eden* \
	$LIBDIR/lib*GL*.so* \
    $LIBDIR/libSDL2*.so* \
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

# Prepare sharun
if [ "$ARCH" = 'aarch64' ]; then
	# allow the host vulkan to be used for aarch64 given the sed situation
	echo 'SHARUN_ALLOW_SYS_VKICD=1' > ./.env
fi

wget https://github.com/VHSgunzo/sharun/releases/download/v0.6.3/sharun-x86_64 -O sharun
chmod a+x sharun

ln -f ./sharun ./AppRun
./sharun -g
