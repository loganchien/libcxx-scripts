#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

export LDFLAGS="-L${OUT_DIR}/lib"

mkdir -p "${LIBCXX_OBJ}"
cd "${LIBCXX_OBJ}"

if [ -z "${CROSS_COMPILING}" ]; then
  CMAKE_FLAGS=(
    "-DCMAKE_INSTALL_PREFIX=${OUT_DIR}"
  )
elif [ "${CROSS_COMPILING}" = "arm" ]; then
  EXTRA_CXX_FLAGS+=" -mfloat-abi=hard"

  # HACK: find cross compiling system include path
  SYSTEM_INCLUDE="/usr/arm-linux-gnueabihf/include"
  if [ -d "${SYSTEM_INCLUDE}" ]; then
    EXTRA_CXX_FLAGS+=" -isystem ${SYSTEM_INCLUDE}"
  fi

  # Clang cross-compiler flags
  case ${CXX} in
    *clang*)
      EXTRA_CXX_FLAGS+=" -target arm-linux-gnueabihf -ccc-gcc-name arm-linux-gnueabihf-gcc-4.7"
      ;;
  esac;

  CMAKE_FLAGS=(
    "-DCMAKE_SYSTEM_PROCESSOR=arm"
    "-DCMAKE_SYSTEM_NAME=Linux"
    "-DCMAKE_CROSSCOMPILING=True"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=${OUT_DIR}"
    "-DCMAKE_CXX_FLAGS=${EXTRA_CXX_FLAGS}"
  )
fi

CMAKE_FLAGS+=(
  "-DLIBCXX_CXX_ABI=libcxxabi"
  "-DLIBCXX_LIBCXXABI_INCLUDE_PATHS=${LIBCXXABI_SRC}/include"
)

cmake -G "Unix Makefiles" "${CMAKE_FLAGS[@]}" "${LIBCXX_SRC}"

make -j16

make install
