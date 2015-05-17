#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

if [ ! -d "${LIBCXX_SRC}" ]; then
  git clone "http://llvm.org/git/libcxx.git" "libcxx"
fi

if [ ! -d "${LIBCXXABI_SRC}" ]; then
  git clone "http://llvm.org/git/libcxxabi.git" "libcxxabi"
fi

if [ ! -d "${LIBUNWIND_SRC}" ]; then
  git clone "http://llvm.org/git/libunwind.git" "libunwind"
fi
