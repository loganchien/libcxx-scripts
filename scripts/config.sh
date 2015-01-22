#!/bin/bash

if [ -z "${SCRIPT_DIR}" ]; then
  echo "WARNING: \${SCRIPT_DIR} is not set properly"
  exit 1
fi

ROOT="$(cd "${SCRIPT_DIR}/.."; pwd)"

LIBCXX_SRC="${ROOT}/libcxx"
LIBCXXABI_SRC="${ROOT}/libcxxabi"

if [ "${CROSS_COMPILING}" = "arm" ]; then
  OBJ_DIR="${ROOT}/objs-arm"
  OUT_DIR="${ROOT}/out-arm"
else
  OBJ_DIR="${ROOT}/objs"
  OUT_DIR="${ROOT}/out"
fi

LIBCXX_OBJ="${OBJ_DIR}/libcxx"
LIBCXXABI_OBJ="${OBJ_DIR}/libcxxabi"
LIBCXXABI_UNITTEST_OUT="${OUT_DIR}/unittests"

if [ -z "${CC}" ]; then
  export CC="clang"
fi

if [ -z "${CXX}" ]; then
  export CXX="clang++"
fi
