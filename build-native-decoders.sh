#!/bin/bash
#
# Fetches (and where needed pre-builds) the native libraries for the Opus, FLAC,
# AV1 and VP9 decoder modules, following each module's README.
#
# Run from the repository root. Requires git, meson, ninja and nasm (for AV1),
# and perl (for VP9). Versions can be overridden through environment variables.
#   NDK_PATH  Android NDK location (default: ~/Android/Sdk/ndk/$NDK_VERSION)

set -euo pipefail

NDK_VERSION="${NDK_VERSION:-28.2.13676358}"
NDK_PATH="${NDK_PATH:-$HOME/Android/Sdk/ndk/${NDK_VERSION}}"
HOST_PLATFORM="linux-x86_64"

OPUS_VERSION="${OPUS_VERSION:-v1.5.2}"
# 1.5.0+ is needed: older releases call ftello(), which 32-bit Android lacks below API 24.
FLAC_VERSION="${FLAC_VERSION:-1.5.0}"
CPU_FEATURES_VERSION="${CPU_FEATURES_VERSION:-v0.10.1}"
DAV1D_VERSION="${DAV1D_VERSION:-1.5.2}"
LIBVPX_VERSION="${LIBVPX_VERSION:-v1.15.2}"

ROOT_DIR="$(pwd)"
LIBRARIES="${ROOT_DIR}/libraries"
echo "NDK path: $NDK_PATH"

clone() {
  local url="$1" ref="$2" dest="$3"
  rm -rf "$dest"
  git -c advice.detachedHead=false clone --depth=1 --branch="$ref" "$url" "$dest"
}

# Opus and FLAC: Gradle's CMake build compiles the cloned sources directly.
echo "=== Opus ${OPUS_VERSION}"
clone https://github.com/xiph/opus.git "$OPUS_VERSION" \
  "${LIBRARIES}/decoder_opus/src/main/jni/libopus"

echo "=== FLAC ${FLAC_VERSION}"
clone https://github.com/xiph/flac.git "$FLAC_VERSION" \
  "${LIBRARIES}/decoder_flac/src/main/jni/libflac"

# AV1: dav1d is pre-built with meson; cpu_features is compiled by CMake.
echo "=== AV1: dav1d ${DAV1D_VERSION}, cpu_features ${CPU_FEATURES_VERSION}"
AV1_MODULE_PATH="${LIBRARIES}/decoder_av1/src/main"
clone https://github.com/google/cpu_features.git "$CPU_FEATURES_VERSION" \
  "${AV1_MODULE_PATH}/jni/cpu_features"
clone https://code.videolan.org/videolan/dav1d.git "$DAV1D_VERSION" \
  "${AV1_MODULE_PATH}/jni/dav1d"
(cd "${AV1_MODULE_PATH}/jni" && ./build_dav1d.sh "${AV1_MODULE_PATH}" "${NDK_PATH}" "${HOST_PLATFORM}")

# VP9: libvpx is configured per ABI, then built with ndk-build into src/main/libs.
echo "=== VP9: libvpx ${LIBVPX_VERSION}"
VP9_MODULE_PATH="${LIBRARIES}/decoder_vp9/src/main"
rm -rf "${VP9_MODULE_PATH}/jni/libvpx_android_configs" "${VP9_MODULE_PATH}/libs" "${VP9_MODULE_PATH}/obj"
clone https://chromium.googlesource.com/webm/libvpx "$LIBVPX_VERSION" "${VP9_MODULE_PATH}/jni/libvpx"
(cd "${VP9_MODULE_PATH}/jni" \
  && ./generate_libvpx_android_configs.sh \
  && "${NDK_PATH}/ndk-build" -j"$(nproc)")

echo "Native decoder libraries are ready."
