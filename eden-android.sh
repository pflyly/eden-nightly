#!/bin/bash -ex

if ! git clone 'https://git.eden-emu.dev/eden-emu/eden.git' ./eden; then
	echo "Using mirror instead..."
	rm -rf ./eden || true
	git clone 'https://github.com/pflyly/eden-mirror.git' ./eden
fi

cd ./eden
git submodule update --init --recursive

COUNT="$(git rev-list --count HEAD)"
# HASH="$(git rev-parse --short HEAD)"
# DATE="$(date +"%Y%m%d")"
APK_NAME="Eden-${COUNT}-Android-Universal"

cd src/android
chmod +x ./gradlew
./gradlew assembleRelease --console=plain --info -Dorg.gradle.caching=true

APK_PATH=$(find app/build/outputs/apk -type f -name "*.apk" | head -n 1)
if [ -z "$APK_PATH" ]; then
    echo "Error: APK not found in expected directory."
    exit 1
fi
mkdir -p artifacts
mv "$APK_PATH" "artifacts/$APK_NAME.apk"
