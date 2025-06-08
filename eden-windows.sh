#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"

# Clone Eden, fallback to mirror if upstream repo fails to clone
if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
git submodule update --init --recursive

if [[ "${ARCH}" == "ARM64" ]]; then
    export EXTRA_CMAKE_FLAGS=(
        -DYUZU_USE_BUNDLED_SDL2=OFF
        -DYUZU_USE_EXTERNAL_SDL2=ON
 	-DYUZU_USE_BUNDLED_FFMPEG=OFF
  	-DFFmpeg_PATH="D:/a/eden-nightly/eden-nightly/eden/externals/vcpkg/packages/ffmpeg_arm64-windows"
    )

    # Add SDL2 & ffmpeg to vcpkg.json
    sed -i '/"fmt",/a \        "sdl2",' vcpkg.json
    sed -i '/"sdl2",/a \        "ffmpeg",' vcpkg.json
    sed -i 's/^\s*include(CopyYuzuFFmpegDeps)/# &/' src/yuzu/CMakeLists.txt
    sed -i 's/^\s*copy_yuzu_FFmpeg_deps(yuzu)/# &/' src/yuzu/CMakeLists.txt

    # Adapt upstream WIP changes
    sed -i '
/#elif defined(ARCHITECTURE_x86_64)/{
    N
    /asm volatile("mfence\\n\\tlfence\\n\\t" : : : "memory");/a\
#elif defined(_MSC_VER) && defined(ARCHITECTURE_arm64)\
                    _Memory_barrier();
}
/#elif defined(ARCHITECTURE_x86_64)/{
    N
    /asm volatile("mfence\\n\\t" : : : "memory");/a\
#elif defined(_MSC_VER) && defined(ARCHITECTURE_arm64)\
                    _Memory_barrier();
}
' src/core/arm/dynarmic/dynarmic_cp15.cpp

    sed -i 's/list(APPEND CMAKE_PREFIX_PATH "${Qt6_DIR}")/list(PREPEND CMAKE_PREFIX_PATH "${Qt6_DIR}")/' CMakeLists.txt
    sed -i '/#include <boost\/asio.hpp>/a #include <boost/version.hpp>' src/core/debugger/debugger.cpp
fi

COUNT="$(git rev-list --count HEAD)"
EXE_NAME="Eden-${COUNT}-Windows-${ARCH}"

mkdir build
cd build
cmake .. -G Ninja \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    "${EXTRA_CMAKE_FLAGS[@]}"
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/eden.exe
mkdir deploy
cp -r bin/* deploy/

if [[ "${ARCH}" == "ARM64" ]]; then
	# Ensure all required FFmpeg DLLs are included (may be partially bundled already — see CI logs)
	cp -v ../externals/vcpkg/packages/ffmpeg_arm64-windows/bin/*.dll deploy/
 
 	# Use ARM64-specific Qt paths with windeployqt
 	"D:/a/eden-nightly/Qt/6.8.3/msvc2022_64/bin/windeployqt.exe" --qtpaths "D:/a/eden-nightly/Qt/6.8.3/msvc2022_arm64/bin/qtpaths6.bat" --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"
else
	windeployqt6 --release --no-compiler-runtime --no-opengl-sw --no-patchqt --no-quick --no-system-dxc-compiler --no-quick-import --no-system-d3d-compiler --dir deploy "$EXE_PATH"
fi

# Delete un-needed debug files 
find deploy -type f -name "*.pdb" -exec rm -fv {} +

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
