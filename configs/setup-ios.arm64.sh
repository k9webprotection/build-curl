#!/bin/bash

ARCH="arm64"
HOST_ARCH="aarch64"

PLATFORM_DEFINITION="defined(__ENVIRONMENT_IPHONE_OS_VERSION_MIN_REQUIRED__) && defined(__arm64__)"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
SDK_VERSION_NAME="iphoneos"
