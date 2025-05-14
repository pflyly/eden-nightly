#!/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

case "$1" in
    steamdeck)
        echo "Making Eden Optimized Build for Steam Deck"
        CMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed"
        CMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -fno-plt -flto=auto -Wno-error -mfpmath=both"
        CMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -fno-plt -flto=auto -Wno-error"
        YUZU_ENABLE_LTO=ON
        TARGET="Steamdeck"
        ;;
    rog)
        echo "Making Eden Optimized Build for ROG Ally X"
        CMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed"
        CMAKE_CXX_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -fno-plt -flto=auto -Wno-error -mfpmath=both"
        CMAKE_C_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -fno-plt -flto=auto -Wno-error"
        YUZU_ENABLE_LTO=ON
        TARGET="ROG_Ally_X"
        ;;
    common)
        echo "Making Eden Optimized Build for Modern CPUs"
        CMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed"
        CMAKE_CXX_FLAGS="-march=x86-64-v3 -O3 -pipe -fno-plt -flto=auto -Wno-error -mfpmath=both"
        CMAKE_C_FLAGS="-march=x86-64-v3 -O3 -pipe -fno-plt -flto=auto -Wno-error"
        YUZU_ENABLE_LTO=ON
        ARCH="${ARCH}_v3"
        TARGET="Common"
        ;;
    aarch64)
        echo "Making Eden Optimized Build for AArch64"
        CMAKE_EXE_LINKER_FLAGS="-Wl,-O3 -Wl,--as-needed"
        CMAKE_CXX_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -w"
        CMAKE_C_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -w"
        YUZU_ENABLE_LTO=ON
        TARGET="AArch64"
        ;;
    check)
        echo "Checking build"
        YUZU_USE_PRECOMPILED_HEADERS=OFF
        CMAKE_CXX_FLAGS="-w"
        CMAKE_C_FLAGS="-w"
        TARGET="Check"
        CCACHE="ccache"
        ;;
esac

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# BUILD Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
DATE="$(date +"%Y%m%d")"
git submodule update --init --recursive -j$(nproc)

# workaround for aarch64, this function has already been removed in citron
if [ "$1" = 'aarch64' ]; then
    sed -i '/sse2neon/d' ./src/video_core/CMakeLists.txt
    sed -i 's|^\(#include <sse2neon\.h>\)|// \1|' ./src/video_core/host1x/vic.cpp
fi

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_USE_BUNDLED_VCPKG=ON \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DUSE_SYSTEM_QT=ON \
    -DYUZU_TESTS=OFF \
    -DYUZU_CHECK_SUBMODULES=OFF \
    -DYUZU_USE_FASTER_LD=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DENABLE_WEB_SERVICE=OFF \
    -DBUNDLE_SPEEX=ON \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER="${CCACHE:-}" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="${CCACHE:-}" \
    ${YUZU_ENABLE_LTO:+-DYUZU_ENABLE_LTO=$YUZU_ENABLE_LTO} \
    ${YUZU_USE_PRECOMPILED_HEADERS:+-DYUZU_USE_PRECOMPILED_HEADERS=$YUZU_USE_PRECOMPILED_HEADERS} \
    ${CMAKE_EXE_LINKER_FLAGS:+-DCMAKE_EXE_LINKER_FLAGS="$CMAKE_EXE_LINKER_FLAGS"} \
    ${CMAKE_CXX_FLAGS:+-DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS"} \
    ${CMAKE_C_FLAGS:+-DCMAKE_C_FLAGS="$CMAKE_C_FLAGS"}
ninja -j$(nproc)
echo "$HASH" >~/hash
echo "$(cat ~/hash)"
ccache -s -v

# Use appimage-builder.sh to generate AppDir
cd ../..
chmod +x ./appimage-builder.sh
./appimage-builder.sh eden ./eden/build
cp /usr/lib/libSDL3.so* ./eden/build/deploy-linux/AppDir/usr/lib/ # Copying libsdl3 to target AppDir

# Prepare uruntime
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

# Turn AppDir into appimage
echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B32 \
--header uruntime -i ./eden/build/deploy-linux/AppDir -o Eden-nightly-"${DATE}"-"${COUNT}"-"${HASH}"-"${TARGET}"-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

echo "All Done!"
