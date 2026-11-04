#!/bin/bash

rm -rf ffmpeg
rm -rf extensions/ffmpeg/buildout/

NDK_VERSION="28.2.13676358"
NDK_PATH="$HOME/Android/Sdk/ndk/${NDK_VERSION}"
HOST_PLATFORM="linux-x86_64"
ENABLED_DECODERS=(vorbis opus flac alac pcm_mulaw pcm_alaw mp3 amrnb amrwb aac ac3 eac3 dca mlp truehd)
ANDROID_ABI=21

FFMPEG_MODULE_PATH=$(realpath "$(pwd)/libraries/decoder_ffmpeg/src/main")
echo "Ffmpeg path: $FFMPEG_MODULE_PATH"

git clone git://source.ffmpeg.org/ffmpeg && \
  cd ffmpeg && \
  git checkout release/6.0 && \
  FFMPEG_PATH="$(pwd)"
echo "Ffmpeg path: $FFMPEG_PATH"

cd "${FFMPEG_MODULE_PATH}/jni" && \
ln -s "$FFMPEG_PATH" ffmpeg

cd "${FFMPEG_MODULE_PATH}/jni" && \
./build_ffmpeg.sh \
  "${FFMPEG_MODULE_PATH}" "${NDK_PATH}" "${HOST_PLATFORM}" "${ANDROID_ABI}" "${ENABLED_DECODERS[@]}"
