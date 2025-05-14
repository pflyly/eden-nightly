#!/bin/bash -ex

echo "Making Eden for MacOS"

export Qt6_DIR="/opt/homebrew/opt/qt@6/lib/cmake"
export LIBVULKAN_PATH=/opt/homebrew/lib/libvulkan.dylib

if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
APP_NAME="Eden-nightly-${DATE}-${COUNT}-${HASH}-MacOS-${TARGET}"

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_TESTS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DENABLE_WEB_SERVICE=OFF \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Find macdeployqt from external Qt installation path
MACDEPLOYQT=$(find ./externals/qt/ -type f -name macdeployqt* | head -n 1)
if [ -z "$MACDEPLOYQT" ]; then
    echo "Error: macdeployqt not found"
    exit 1
fi
echo "Found macdeployqt at: $MACDEPLOYQT"

# Pack for upload
"$MACDEPLOYQT" ./bin/eden.app -verbose=2
mkdir -p artifacts
mkdir "$APP_NAME"
mv ./bin/eden.app "$APP_NAME"
ZIP_NAME="$APP_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$APP_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
