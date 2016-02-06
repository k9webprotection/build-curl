#!/bin/bash

SDK_FLAG="${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}"
HOST="${HOST_ARCH}-apple-darwin"
SSL_FLAG="--with-darwinssl"
THREAD_FLAG="--enable-threaded-resolver"

export CC="${CLANG_PATH}"
export CPPFLAGS="-arch ${ARCH} -m${SDK_FLAG} -fPIC -fembed-bitcode -isysroot ${SDK_PATH}"
export LDFLAGS="-arch ${ARCH} -m${SDK_FLAG} -isysroot ${SDK_PATH}"
