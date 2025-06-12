#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

BUILD_DIR=$(realpath "$1")
APPDIR="${BUILD_DIR}/mesa/AppDir"
mkdir -p "${APPDIR}"
cd "${APPDIR}"

# Install eden
sudo ninja install

cp -v /usr/share/applications/org.eden_emu.eden.desktop ./eden.desktop
cp -v /usr/share/icons/hicolor/scalable/apps/org.eden_emu.eden.svg ./eden.svg
ln -sfv ./eden.svg ./.DirIcon
    
# temp workaround for arch being silly
mkdir -p share/X11
cp -r /usr/share/X11/xkb share/X11
    
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -e -s -k \
    /usr/bin/eden \
    /usr/lib/libSDL* \
    /usr/lib/libXss.so* \
    /usr/lib/libgamemode.so* \
    /usr/lib/qt6/plugins/imageformats/* \
    /usr/lib/qt6/plugins/iconengines/* \
    /usr/lib/qt6/plugins/platforms/* \
    /usr/lib/qt6/plugins/platformthemes/* \
    /usr/lib/qt6/plugins/platforminputcontexts/* \
    /usr/lib/qt6/plugins/styles/* \
    /usr/lib/qt6/plugins/xcbglintegrations/* \
    /usr/lib/qt6/plugins/wayland-*/* \
    /usr/lib/pulseaudio/* \
    /usr/lib/spa-0.2/*/* \
    /usr/lib/alsa-lib/* \
    /usr/lib/lib*GL*.so* \
    /usr/lib/dri/* \
    /usr/lib/vdpau/* \
    /usr/lib/libvulkan* \
    /usr/lib/libdecor-0.so*

ln -fv ./sharun ./AppRun
./sharun -g
