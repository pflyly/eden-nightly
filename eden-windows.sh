#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"
export PATH="$PATH:/c/ProgramData/chocolatey/bin"

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
EXE_NAME="Eden-nightly-${DATE}-${COUNT}-${HASH}-Windows-MSVC"

mkdir build
cd build
cmake .. -G Ninja \
    -DYUZU_TESTS=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
ninja

# Use windeployqt to gather dependencies
EXE_PATH=./bin/eden.exe
mkdir deploy
cp -r bin/* deploy/
"D:/a/eden-nightly/eden-nightly/eden/build/externals/qt/6.7.3/msvc2019_64/bin/windeployqt.exe" --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --dir deploy "$EXE_PATH"

# Delete un-needed debug files 
find deploy -type f -name "*.pdb" -exec rm -f {} +
# Delete DX components, users should have them already
rm -f deploy/dxcompiler.dll
rm -f deploy/dxil.dll

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r deploy/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
