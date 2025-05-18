#!/bin/bash -ex

echo "Making Eden for MacOS"
if [ "$TARGET" = "arm64" ]; then
    export LIBVULKAN_PATH=/opt/homebrew/lib/libvulkan.1.dylib
else
    export LIBVULKAN_PATH=/usr/local/lib/libvulkan.1.dylib
fi

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
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DUSE_SYSTEM_QT=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET" \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Bundle and code-sign eden.app
APP=./bin/eden.app
macdeployqt "$APP" -verbose=2
codesign --deep --force --verify --verbose --sign - "$APP"

# Pack for upload
mkdir -p artifacts
mkdir "$APP_NAME"
cp -r ./bin/* "$APP_NAME"
ZIP_NAME="$APP_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$APP_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
