#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"

case "$1" in
    steamdeck)
        echo "Making Eden Optimized Build for Steam Deck"
        CMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=auto -Wno-error"
        CMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=auto -Wno-error"
	YUZU_USE_PRECOMPILED_HEADERS=OFF
	CCACHE="ccache"
        TARGET="Steamdeck"
        ;;
    common)
        echo "Making Eden Optimized Build for Modern CPUs"
        CMAKE_CXX_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -Wno-error"
        CMAKE_C_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -Wno-error"
	YUZU_USE_PRECOMPILED_HEADERS=OFF
	CCACHE="ccache"
        ARCH="${ARCH}_v3"
        TARGET="Common"
        ;;	
    aarch64)
        echo "Making Eden Optimized Build for AArch64"
        CMAKE_CXX_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -w"
        CMAKE_C_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -w"
        TARGET="Linux"
        ;;
esac

UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*$ARCH.AppImage.zsync"

# Clone Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
git submodule update --init --recursive

# Get current commit info
DATE="$(date +"%Y%m%d")"
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
TAG="$(git describe --tags)"
echo "$HASH" > ~/hash
echo "$COUNT" > ~/count

# Start to generate release info and changelog
CHANGELOG_FILE=~/changelog
BASE_COMMIT_URL="https://git.eden-emu.dev/eden-emu/eden/commit"
BASE_COMPARE_URL="https://git.eden-emu.dev/eden-emu/eden/compare"
START_COUNT=$(git rev-list --count "$OLD_HASH")
i=$((START_COUNT + 1))

# Add Release overview link and instruction
echo "This repository is intended to provide an easy way to try out the latest features from recent commits — that's what **Nightly** builds are for!" > "$CHANGELOG_FILE"
echo "These builds are **experimental and may be unstable**, so use them at your own discretion." >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"
echo "> [!IMPORTANT]" >> "$CHANGELOG_FILE"
echo "> See the **[Release Overview](https://github.com/pflyly/eden-nightly?tab=readme-ov-file#release-overview)** section for detailed differences between builds." >> "$CHANGELOG_FILE"
echo >> "$CHANGELOG_FILE"

# Add changelog section
echo "Changelog:" >> "$CHANGELOG_FILE"
git log --reverse --pretty=format:"%H %s" "${OLD_HASH}..HEAD" | while IFS= read -r line || [ -n "$line" ]; do
  full_hash="${line%% *}"
  msg="${line#* }"
  short_hash="$(git rev-parse --short "$full_hash")"
  echo -e "- Merged commit: \`${i}\` [\`${short_hash}\`](${BASE_COMMIT_URL}/${full_hash})\n  ${msg}" >> "$CHANGELOG_FILE"
  echo >> "$CHANGELOG_FILE"
  i=$((i + 1))
done

# Add full changelog from lastest tag release
RELEASE_TAG="$(echo "$TAG" | awk -F'-' '{print $1 "-" $2 "-" $3}')"
echo "Full Changelog: [\`${RELEASE_TAG}...master\`](${BASE_COMPARE_URL}/${RELEASE_TAG}...master)" >> "$CHANGELOG_FILE"

# workaround for aarch64
if [ "$1" = 'aarch64' ]; then
    sed -i 's/Settings::values\.lru_cache_enabled\.GetValue()/true/' src/core/arm/nce/patcher.h
fi

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_USE_BUNDLED_VCPKG=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DUSE_SYSTEM_QT=ON \
    -DYUZU_TESTS=OFF \
    -DYUZU_CHECK_SUBMODULES=OFF \
    -DYUZU_USE_FASTER_LD=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--as-needed" \
    -DCMAKE_C_COMPILER_LAUNCHER="${CCACHE:-}" \
    -DCMAKE_CXX_COMPILER_LAUNCHER="${CCACHE:-}" \
    ${YUZU_USE_PRECOMPILED_HEADERS:+-DYUZU_USE_PRECOMPILED_HEADERS=$YUZU_USE_PRECOMPILED_HEADERS} \
    ${CMAKE_CXX_FLAGS:+-DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS"} \
    ${CMAKE_C_FLAGS:+-DCMAKE_C_FLAGS="$CMAKE_C_FLAGS"}
ninja

if [ "$1" != 'aarch64' ]; then
    ccache -s -v
fi

cd ../..
# Use sharun to generate AppDir
chmod +x ./sharun.sh
./sharun.sh ./eden/build

# Prepare uruntime
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime

# Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime --appimage-addupdinfo "$UPINFO"

# Turn AppDir into appimage
echo "Generating AppImage with mesa"
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B32 \
--header uruntime -i ./eden/build/mesa/AppDir -o Eden-"${COUNT}"-"${TARGET}"-"$ARCH".AppImage

# echo "Generating AppImage without mesa"
#./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B32 \
#--header uruntime -i ./eden/build/light/AppDir -o Eden-"${COUNT}"-"${TARGET}"-light-"$ARCH".AppImage

for appimage in *.AppImage; do
  echo "Generating zsync file for $appimage"
  zsyncmake -v "$appimage" -u "$appimage"
done

echo "All Done!"
