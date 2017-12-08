#!/bin/bash

PFIX="${ANDROID_NDK_HOME}/toolchains/${GCC_ARCH}-${ANDROID_GCC_VERSION}/prebuilt/darwin-x86_64/bin/${GCC_PREFIX}"
HOST="arm-linux-androideabi"
THREAD_FLAG="--enable-threaded-resolver"
[ -n "${OPENSSL_TARGET}" ] || { echo "Building for android requires OPENSSL_TARGET to be set"; exit 1; }

export SYSROOT="${ANDROID_NDK_HOME}/sysroot"
export PLATROOT="${ANDROID_NDK_HOME}/platforms/android-${ANDROID_PLATFORM}/arch-${PLATFORM_ARCH}"
export SYSINC="${SYSROOT}/usr/include/${GCC_PREFIX}"
export CC="${PFIX}-gcc"
export RANLIB="${PFIX}-ranlib"
export AR="${PFIX}-ar"
export AS="${PFIX}-as"
export CPP="${PFIX}-cpp"
export CXX="${PFIX}-g++"
export LD="${PFIX}-ld"
export STRIP="${PFIX}-strip"
export CFLAGS="--sysroot=${SYSROOT} ${COMP_FLAGS}"
export CPPFLAGS="-isystem${SYSROOT}/usr/include -isystem${SYSINC} -D__ANDROID_API__=${ANDROID_PLATFORM}"
export LDFLAGS="--sysroot=${PLATROOT}"

ANDROID_BUILD_PIE="${ANDROID_BUILD_PIE:-true}"
if [ "${ANDROID_BUILD_PIE}" == "true" ]; then
    export CFLAGS="${CFLAGS} -fPIE"
    export LDFLAGS="${LDFLAGS} -fPIE -pie"
fi
