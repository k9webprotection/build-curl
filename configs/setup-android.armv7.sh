#!/bin/bash

OPENSSL_CONFIGURE_NAME="android-armv7"
GCC_ARCH="arm-linux-androideabi"
GCC_PREFIX="arm-linux-androideabi"
PLATFORM_ARCH="arm"
COMP_FLAGS="-mfloat-abi=softfp -mfpu=vfpv3-d16 -mthumb"
PLATFORM_DEFINITION="defined(__ANDROID__) && defined(__arm__)"

return 0
