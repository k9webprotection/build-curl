#!/bin/bash

SDK_FLAG="${SDK_VERSION_NAME}-version-min=${MIN_OS_VERSION}"
HOST="${HOST_ARCH}-apple-darwin"
THREAD_FLAG="--enable-threaded-resolver"
[ -z "${OPENSSL_TARGET}" ] && { SSL_FLAG="--with-darwinssl"; } || { SSL_FLAG="--without-darwinssl"; }

export CC="${CLANG_PATH}"
export CFLAGS="-arch ${ARCH} -m${SDK_FLAG} -fPIC -fembed-bitcode -isysroot ${SDK_PATH}"
export CPPFLAGS="-arch ${ARCH} -m${SDK_FLAG} -fPIC -fembed-bitcode -isysroot ${SDK_PATH}"
export LDFLAGS="-arch ${ARCH} -m${SDK_FLAG} -isysroot ${SDK_PATH}"
