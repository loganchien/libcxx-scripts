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
  CMAKE_FLAGS=(
    "-DCMAKE_SYSTEM_PROCESSOR=arm"
    "-DCMAKE_SYSTEM_NAME=Linux"
    "-DCMAKE_CROSSCOMPILING=True"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_PREFIX=${OUT_DIR}"
    "-DCMAKE_CXX_FLAGS=-target arm-linux-gnueabihf -mfloat-abi=hard -ccc-gcc-name arm-linux-gnueabihf-gcc-4.7"
  )
fi

CMAKE_FLAGS+=(
  "-DLIBCXX_CXX_ABI=libcxxabi"
  "-DLIBCXX_LIBCXXABI_INCLUDE_PATHS=${LIBCXXABI_SRC}/include"
)

cmake -G "Unix Makefiles" "${CMAKE_FLAGS[@]}" "${LIBCXX_SRC}"

make -j16

make install
