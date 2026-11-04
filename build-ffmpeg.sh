#!/bin/bash
#
# Builds the FFmpeg static libraries used by libraries/decoder_ffmpeg.
#
# Run from the repository root. Defaults suit a local Android Studio setup; CI
# overrides them through environment variables:
#   NDK_PATH        Android NDK location (default: ~/Android/Sdk/ndk/$NDK_VERSION)
#   FFMPEG_GIT_URL  FFmpeg git remote
#   FFMPEG_BRANCH   FFmpeg branch to build

set -euo pipefail

NDK_VERSION="${NDK_VERSION:-28.2.13676358}"
NDK_PATH="${NDK_PATH:-$HOME/Android/Sdk/ndk/${NDK_VERSION}}"
HOST_PLATFORM="linux-x86_64"
ENABLED_DECODERS=(vorbis opus flac alac pcm_mulaw pcm_alaw mp3 amrnb amrwb aac ac3 eac3 dca mlp truehd)
ANDROID_ABI=21
FFMPEG_GIT_URL="${FFMPEG_GIT_URL:-https://git.ffmpeg.org/ffmpeg.git}"
FFMPEG_BRANCH="${FFMPEG_BRANCH:-release/6.0}"

ROOT_DIR="$(pwd)"
FFMPEG_MODULE_PATH=$(realpath "${ROOT_DIR}/libraries/decoder_ffmpeg/src/main")
echo "Ffmpeg module path: $FFMPEG_MODULE_PATH"
echo "NDK path: $NDK_PATH"

rm -rf "${ROOT_DIR}/ffmpeg"
rm -f "${FFMPEG_MODULE_PATH}/jni/ffmpeg"

git clone --depth=1 --branch="${FFMPEG_BRANCH}" "${FFMPEG_GIT_URL}" "${ROOT_DIR}/ffmpeg"
FFMPEG_PATH="${ROOT_DIR}/ffmpeg"
echo "Ffmpeg path: $FFMPEG_PATH"

ln -s "$FFMPEG_PATH" "${FFMPEG_MODULE_PATH}/jni/ffmpeg"

cd "${FFMPEG_MODULE_PATH}/jni"
./build_ffmpeg.sh \
  "${FFMPEG_MODULE_PATH}" "${NDK_PATH}" "${HOST_PLATFORM}" "${ANDROID_ABI}" "${ENABLED_DECODERS[@]}"
