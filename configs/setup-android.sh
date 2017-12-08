#!/bin/bash

GEN_SCRIPT="${CONFIGS_DIR}/common-gcc-android.sh"

[ -n "${ANDROID_NDK_HOME}" -a -x "${ANDROID_NDK_HOME}/ndk-build" ] || {
    echo "ANDROID_NDK_HOME is not set to a valid location (${ANDROID_NDK_HOME})"
    return 1
}

ANDROID_GCC_VERSION="${ANDROID_GCC_VERSION:-4.9}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-22}"
CURL_PRECONFIGURE="${CONFIGS_DIR}/preconfigure-android.sh"
