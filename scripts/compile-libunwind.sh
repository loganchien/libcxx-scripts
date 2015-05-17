#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

if [ "${ENABLE_LIBUNWIND}" != "1" ]; then
  exit
fi

# debug flags
EXTRA_C_FLAGS="-O0 -g"
EXTRA_CXX_FLAGS="-O0 -g"

# common flags
CMAKE_FLAGS=(
  "-DCMAKE_INSTALL_PREFIX=${OUT_DIR}"
  "-DCMAKE_BUILD_TYPE=Debug"
  "-DCMAKE_C_COMPILER=clang"
  "-DCMAKE_CXX_COMPILER=clang++"
  "-DLLVM_ABI_BREAKING_CHECKS=WITH_ASSERTS"
)

# add libc++abi to header search path (for __cxxabi_config.h)
EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -I${LIBCXXABI_SRC}/include"
EXTRA_C_FLAGS="${EXTRA_C_FLAGS} -I${LIBCXXABI_SRC}/include"

if [ "${CROSS_COMPILING}" = "arm" ]; then
  echo "WARNING: $0 is experimental.  It may not work with cross-compiling."

  # HACK: find cross compiling system include path
  DIR="/usr/arm-linux-gnueabihf/include"
  if [ -d "${DIR}" ]; then
    EXTRA_C_FLAGS="${EXTRA_C_FLAGS} -isystem ${DIR}"
    EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"

    DIR="${DIR}/c++"
    if [ -d "${DIR}" ]; then
      VER="$(ls "${DIR}")"

      DIR="${DIR}/${VER}"
      if [ -d "${DIR}" ]; then
        EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"
      fi

      DIR="${DIR}/arm-linux-gnueabihf"
      if [ -d "${DIR}" ]; then
        EXTRA_CXX_FLAGS="${EXTRA_CXX_FLAGS} -isystem ${DIR}"
      fi
    fi
  fi

  EXTRA_C_FLAGS="--target=arm-linux-gnueabihf ${EXTRA_C_FLAGS}"
  EXTRA_CXX_FLAGS="--target=arm-linux-gnueabihf ${EXTRA_CXX_FLAGS}"

  CMAKE_FLAGS+=(
    "-DCMAKE_SYSTEM_PROCESSOR=arm"
    "-DCMAKE_SYSTEM_NAME=Linux"
    "-DCMAKE_CROSSCOMPILING=True"
  )
fi

# libunwind flags
CMAKE_FLAGS+=(
  "-DLIBUNWIND_ENABLE_ASSERTIONS=1"
  "-DLIBUNWIND_ENABLE_PEDANTIC=1"
  "-DLIBUNWIND_ENABLE_SHARED=1"
  "-DCMAKE_C_FLAGS=${EXTRA_C_FLAGS}"
  "-DCMAKE_CXX_FLAGS=${EXTRA_CXX_FLAGS}"
)
#"-DLIBUNWIND_ENABLE_WERROR=1"

mkdir -p "${LIBUNWIND_OBJ}"
cd "${LIBUNWIND_OBJ}"

cmake -G "Unix Makefiles" "${CMAKE_FLAGS[@]}" "${LIBUNWIND_SRC}"

make -j16

make install

echo done.
