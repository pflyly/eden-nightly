#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1 
export ARCH=$(uname -m)

BUILD_DIR=$(realpath "$1")
DEPLOY_DIR="${BUILD_DIR}/deploy"
APPDIR="${BUILD_DIR}/deploy/AppDir"

mkdir -p "${DEPLOY_DIR}"
cd "${BUILD_DIR}"

# Install base files to AppDir
DESTDIR="${APPDIR}" ninja install

cd "${DEPLOY_DIR}"

# Prepare linuxdepoly
curl -fsSLo ./linuxdeploy "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"
chmod +x ./linuxdeploy
curl -fsSLo ./linuxdeploy-plugin-qt "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-${ARCH}.AppImage"
chmod +x ./linuxdeploy-plugin-qt
curl -fsSLo ./linuxdeploy-plugin-checkrt.sh https://github.com/darealshinji/linuxdeploy-plugin-checkrt/releases/download/continuous/linuxdeploy-plugin-checkrt.sh
chmod +x ./linuxdeploy-plugin-checkrt.sh

# Setup linuxdeploy environment variables
export QMAKE="/usr/bin/qmake6"
export QT_SELECT=6
export QT_QPA_PLATFORM="wayland;xcb"
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so;libqxcb.so"
export EXTRA_QT_PLUGINS="svg;wayland-decoration-client;wayland-graphics-integration-client;wayland-shell-integration;waylandcompositor;xcb-gl-integration;platformthemes/libqt6ct.so"

# start to deploy
NO_STRIP=1 ./linuxdeploy --appdir ./AppDir --plugin qt --plugin checkrt

# remove libwayland-client because it has platform-dependent exports and breaks other OSes
rm -fv ./AppDir/usr/lib/libwayland-client.so*

# remove libvulkan because it causes issues with gamescope
rm -fv ./AppDir/usr/lib/libvulkan.so*

# Bundle libsdl3 to AppDir, needed for steamdeck
cp /usr/lib/libSDL3.so* ./AppDir/usr/lib/
