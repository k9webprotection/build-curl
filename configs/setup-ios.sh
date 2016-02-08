#!/bin/bash

LIPO_PATH="$(which lipo)"
GEN_SCRIPT="${CONFIGS_DIR}/common-clang-darwin.sh"

CLANG_PATH="$(xcrun -f clang)"
MIN_OS_VERSION="${MIN_OS_VERSION:-7.0}"
