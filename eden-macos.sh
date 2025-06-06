#!/bin/bash -ex

echo "Making Eden for MacOS"
if [ "$TARGET" = "arm64" ]; then
    export LIBVULKAN_PATH="/opt/homebrew/lib/libvulkan.1.dylib"
    INCLUDE_DIR="/opt/homebrew/include/libavcodec"
else
    export LIBVULKAN_PATH="/usr/local/lib/libvulkan.1.dylib"
    INCLUDE_DIR="/usr/local/include/libavcodec"
fi

# Workaround for ffmpeg
git clone --depth=1 https://github.com/FFmpeg/FFmpeg.git ffmpeg
cd ffmpeg
./configure \
    --disable-avdevice \
    --arch=$TARGET \
    --disable-avformat \
    --disable-doc \
    --disable-everything \
    --disable-ffmpeg \
    --disable-ffprobe \
    --disable-network \
    --disable-swresample \
    --disable-vaapi \
    --disable-vdpau \
    --enable-decoder=h264 \
    --enable-decoder=vp8 \
    --enable-decoder=vp9 \
    --enable-avfilter \
    --enable-shared \
    --disable-iconv \
    --enable-filter=yadif,scale
cp -v ./libavcodec/codec_internal.h ./config.h "$INCLUDE_DIR/"

cd ..
# Clone Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
APP_NAME="Eden-${COUNT}-MacOS-${TARGET}"

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DUSE_SYSTEM_MOLTENVK=ON \
    -DYUZU_USE_BUNDLED_FFMPEG=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET" \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DYUZU_USE_PRECOMPILED_HEADERS=OFF 
ninja
ccache -s -v

# Bundle and code-sign eden.app. Excute twice to resolve the qt framework missing error, thanks to @hauntek!
APP=./bin/eden.app
macdeployqt "$APP"
macdeployqt "$APP" -always-overwrite -verbose=2

# FixMachOLibraryPaths
find "$APP/Contents/Frameworks" ""$APP/Contents/MacOS"" -type f \( -name "*.dylib" -o -perm +111 \) | while read file; do
    if file "$file" | grep -q "Mach-O"; then
        otool -L "$file" | awk '/@rpath\// {print $1}' | while read lib; do
            lib_name="${lib##*/}"
            new_path="@executable_path/../Frameworks/$lib_name"
            install_name_tool -change "$lib" "$new_path" "$file"
        done

        if [[ "$file" == *.dylib ]]; then
            lib_name="${file##*/}"
            new_id="@executable_path/../Frameworks/$lib_name"
            install_name_tool -id "$new_id" "$file"
        fi
    fi
done
codesign --deep --force --verify --verbose --sign - "$APP"

# Pack for upload
mkdir -p artifacts
mkdir "$APP_NAME"
cp -r ./bin/* "$APP_NAME"
ZIP_NAME="$APP_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$APP_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
