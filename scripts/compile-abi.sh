#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

OUTPUT="libc++abi.so"
OUTPUT_MAJOR="1"
OUTPUT_MINOR="0"
OUTPUT_FULL="${OUTPUT}.${OUTPUT_MAJOR}.${OUTPUT_MINOR}"

CC="clang"

CXX="clang++"

CFLAGS="-fstrict-aliasing -Wstrict-aliasing=2 \
        -Wsign-conversion -Wshadow -Wconversion -Wunused-variable \
        -Wmissing-field-initializers -Wchar-subscripts -Wmismatched-tags \
        -Wmissing-braces -Wshorten-64-to-32 -Wsign-compare \
        -Wstrict-aliasing=2 -Wstrict-overflow=4 -Wunused-parameter \
        -Wnewline-eof -fPIC -fno-integrated-as"

# libc++ headers
CFLAGS="${CFLAGS} -isystem ${LIBCXX_SRC}/include"

# debug flags
CFLAGS="${CFLAGS} -O0 -g"

CXXFLAGS="-std=c++11 ${CFLAGS}"

LDFLAGS="-shared -nodefaultlibs -Wl,-soname,libc++abi.so.1 \
         -lpthread -lrt -ldl -lc"

if [ "${CROSS_COMPILING}" = "arm" ]; then
  CFLAGS="-target arm-linux-gnueabihf ${CFLAGS}"
  CXXFLAGS="-target arm-linux-gnueabihf ${CXXFLAGS}"
  LDFLAGS="-target arm-linux-gnueabihf ${LDFLAGS}"
fi

if [ -e "${LIBCXXABI_OBJ}" ]; then
  rm -rf "${LIBCXXABI_OBJ}"
fi
mkdir -p "${LIBCXXABI_OBJ}"
cd "${LIBCXXABI_OBJ}"

for FILE in ${LIBCXXABI_SRC}/src/*.cpp; do
  echo "compile: ${FILE}"
  ${CXX} -c $CXXFLAGS "-I${LIBCXXABI_SRC}/include" $OPTIONS $FILE
done

if [ "${CROSS_COMPILING}" = "arm" -a "${ENABLE_LIBUNWIND}" = "1" ]; then
  LIBUNWIND_FILES="
  ${LIBCXXABI_SRC}/src/Unwind/Unwind-EHABI.cpp
  ${LIBCXXABI_SRC}/src/Unwind/libunwind.cpp
  "

  for FILE in ${LIBUNWIND_FILES}; do
    echo "compile: ${FILE}"
    ${CXX} -c $CXXFLAGS "-I${LIBCXXABI_SRC}/include" $OPTIONS $FILE
  done

  LIBUNWIND_FILES="
  ${LIBCXXABI_SRC}/src/Unwind/Unwind-sjlj.c
  ${LIBCXXABI_SRC}/src/Unwind/UnwindLevel1-gcc-ext.c
  ${LIBCXXABI_SRC}/src/Unwind/UnwindLevel1.c
  ${LIBCXXABI_SRC}/src/Unwind/UnwindRegistersRestore.S
  ${LIBCXXABI_SRC}/src/Unwind/UnwindRegistersSave.S
  "

  for FILE in ${LIBUNWIND_FILES}; do
    echo "compile: ${FILE}"
    ${CC} -c $CFLAGS "-I${LIBCXXABI_SRC}/include" $OPTIONS $FILE
  done
fi

echo "link: ${OUTPUT_FULL}"
$CC -o "${OUTPUT_FULL}" *.o $LDFLAGS $CXXFLAGS

echo "installing ..."
mkdir -p "${OUT_DIR}/lib"
cp "${LIBCXXABI_OBJ}/${OUTPUT_FULL}" "${OUT_DIR}/lib"
(cd "${OUT_DIR}/lib"; ln -sf "${OUTPUT_FULL}" "${OUTPUT}.${OUTPUT_MAJOR}")
(cd "${OUT_DIR}/lib"; ln -sf "${OUTPUT_FULL}" "${OUTPUT}")

rm -r "${LIBCXXABI_OBJ}"

echo done.
