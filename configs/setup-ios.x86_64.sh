#!/bin/bash

ARCH="x86_64"
HOST_ARCH="${ARCH}"
PLATFORM_DEFINITION="defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && defined(__x86_64__)"
SDK_PATH="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SDK_VERSION_NAME="ios-simulator"
