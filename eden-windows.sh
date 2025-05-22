#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"
export ARCH="$(uname -m)"

# We really need to hanlde this due to frequent failure of submodule update
clone_eden() {
	# Clone Eden, fallback to mirror if upstream repo fails to clone
	if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
		echo "Using mirror instead..."
		rm -rf ./eden || true
		git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
	fi
}

rm -rf ./eden || true
clone_eden
cd ./eden

if ! git submodule update --init --recursive; then
    echo "Submodule update failed! Deleting and re-cloning the entire repo."
    
    # Re-cloning the entire repo in case of submodule corruption
    cd ..
    rm -rf ./eden || true
    clone_eden
    cd ./eden

    # Now try submodules again — if this fails again, let it explode!!!
    git submodule update --init --recursive
fi

COUNT="$(git rev-list --count HEAD)"
EXE_NAME="Eden-${COUNT}-Windows-${ARCH}"

mkdir build
cd build
cmake .. -G Ninja \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DYUZU_USE_QT_MULTIMEDIA=OFF \
    -DYUZU_USE_QT_WEB_ENGINE=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DENABLE_WEB_SERVICE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/eden.exe
mkdir deploy
cp -r bin/* deploy/
windeployqt --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"

# Delete un-needed debug files 
find deploy -type f -name "*.pdb" -exec rm -fv {} +
# Delete DX components, users should have them already
rm -fv deploy/dxcompiler.dll
rm -fv deploy/dxil.dll

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
