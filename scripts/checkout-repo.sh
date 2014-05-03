#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

if [ ! -d "${LIBCXX_SRC}" ]; then
  git clone "https://github.com/loganchien/libcxx" "libcxx"
  git checkout "awong-dev-ndk"
fi

if [ ! -d "${LIBCXXABI_SRC}" ]; then
  git clone "https://github.com/loganchien/libcxxabi" "libcxxabi"
  cd "${LIBCXXABI_SRC}"
  git checkout "awong-dev-ndk"
fi
