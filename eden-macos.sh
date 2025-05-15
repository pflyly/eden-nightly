#!/bin/bash -ex

echo "Making Eden for MacOS"
if [ "$TARGET" = "arm64" ]; then
    export LIBVULKAN_PATH=/opt/homebrew/lib/libvulkan.dylib
else
    export LIBVULKAN_PATH=/usr/local/lib/libvulkan.dylib
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
    -DENABLE_WEB_SERVICE=OFF \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET" \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Pack for upload
APP=./bin/eden.app
macdeployqt "$APP" -verbose=3
cp "$LIBVULKAN_PATH" "$APP/Contents/Frameworks/"
install_name_tool -change "$LIBVULKAN_PATH" "@executable_path/../Frameworks/libvulkan.dylib" "$APP/Contents/MacOS/eden"
codesign --deep --force --verify --verbose --sign - ./bin/eden.app
mkdir -p artifacts
mkdir "$APP_NAME"
cp -r ./bin/* "$APP_NAME"
ZIP_NAME="$APP_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$APP_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
