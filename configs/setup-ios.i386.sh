#!/bin/bash

ARCH="i386"
HOST_ARCH="${ARCH}"
PLATFORM_DEFINITION="defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && defined(__i386__)"
SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SDK_VERSION_NAME="ios-simulator"
