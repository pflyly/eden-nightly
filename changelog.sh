#!/bin/bash

set -ex

# Get current commit info
DATE="$(date +"%Y-%m-%d")"
COUNT="$(git rev-list --count HEAD)"
HASH="$(git rev-parse --short HEAD)"
TAG="$(git describe --tags)"
echo "$HASH" > ~/hash
echo "$COUNT" > ~/count

# Start to generate release info and changelog
CHANGELOG_FILE=~/changelog
BASE_COMMIT_URL="https://git.eden-emu.dev/eden-emu/eden/commit"
BASE_COMPARE_URL="https://git.eden-emu.dev/eden-emu/eden/compare"
BASE_DOWNLOAD_URL="https://github.com/pflyly/eden-nightly/releases/download" # /2025-05-31-fb3988a78/Eden-27334-Android-Coexist.apk
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
