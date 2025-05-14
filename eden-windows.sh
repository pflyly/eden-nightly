#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"
export PATH="$PATH:/c/ProgramData/chocolatey/bin"
export ARCH="$(uname -m)"

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
EXE_NAME="Eden-nightly-${DATE}-${COUNT}-${HASH}-Windows-MSVC-${ARCH}"

mkdir build
cd build
cmake .. -G Ninja \
    -DYUZU_TESTS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DENABLE_WEB_SERVICE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Find windeployqt.exe from external Qt installation path
WINDEPLOYQT_EXE=$(find ./externals/qt -type f -name windeployqt.exe | head -n 1)
if [ -z "$WINDEPLOYQT_EXE" ]; then
    echo "Error: windeployqt.exe not found"
    exit 1
fi
echo "Found windeployqt at: $WINDEPLOYQT_EXE"

# Use windeployqt to gather dependencies
EXE_PATH=./bin/eden.exe
mkdir deploy
cp -r bin/* deploy/
"$WINDEPLOYQT_EXE" --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"

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
