#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

OUTPUT="libc++abi.so"
OUTPUT_MAJOR="1"
OUTPUT_MINOR="0"
OUTPUT_FULL="${OUTPUT}.${OUTPUT_MAJOR}.${OUTPUT_MINOR}"

CFLAGS="-fstrict-aliasing -Wstrict-aliasing=2 \
        -Wsign-conversion -Wshadow -Wconversion -Wunused-variable \
        -Wmissing-field-initializers -Wchar-subscripts \
        -Wmissing-braces -Wsign-compare \
        -Wstrict-aliasing=2 -Wstrict-overflow=4 -Wunused-parameter \
        -fPIC -funwind-tables \
        -D__STDC_FORMAT_MACROS=1"

case "${CC}" in
  *clang*)
    CFLAGS+="-Wmismatched-tags -Wshorten-64-to-32 -Wnewline-eof \
             -fno-integrated-as"
    ;;
esac

# libc++ headers
CFLAGS="${CFLAGS} -isystem ${LIBCXX_SRC}/include"

# debug flags
CFLAGS="${CFLAGS} -O0 -g"


if [ "${ENABLE_LIBUNWIND}" = 1 ]; then
  CFLAGS="$CFLAGS -DLIBCXXABI_USE_LLVM_UNWINDER=1"
fi

CXXFLAGS="-std=c++11 ${CFLAGS}"

LDFLAGS="-shared -nodefaultlibs -Wl,-soname,libc++abi.so.1 \
         -lpthread -lrt -ldl -lc"

if [ "${CROSS_COMPILING}" = "arm" ]; then
  # HACK: find cross compiling system include path
  SYSTEM_INCLUDE="/usr/arm-linux-gnueabihf/include"
  if [ -d "${SYSTEM_INCLUDE}" ]; then
    CFLAGS="${CFLAGS} -isystem ${SYSTEM_INCLUDE}"
    CXXFLAGS="${CXXFLAGS} -isystem ${SYSTEM_INCLUDE}"
  fi

  case "${CC}" in
    *clang*)
      CFLAGS="-target arm-linux-gnueabihf ${CFLAGS}"
      CXXFLAGS="-target arm-linux-gnueabihf ${CXXFLAGS}"
      LDFLAGS="-target arm-linux-gnueabihf ${LDFLAGS}"
      ;;
  esac
fi

# check for __cxa_thread_atexit_impl()
set +e

cat > test.cpp <<__EOF__
extern "C" int __cxa_thread_atexit_impl(void (*dtor)(void *), void *, void *);
int main() {
  __cxa_thread_atexit_impl(0, 0, 0);
}
__EOF__

${CXX} ${CFLAGS} ${CXXFLAGS} test.cpp -o /dev/null > /dev/null 2>&1

if [ $? = 0 ]; then
  CXXFLAGS="${CXXFLAGS} -DHAVE___CXA_THREAD_ATEXIT_IMPL=1"
fi

rm test.cpp a.out > /dev/null 2>&1

set -e

if [ -e "${LIBCXXABI_OBJ}" ]; then
  rm -rf "${LIBCXXABI_OBJ}"
fi
mkdir -p "${LIBCXXABI_OBJ}"
cd "${LIBCXXABI_OBJ}"

CXXFLAGS="${CXXFLAGS} -I${LIBCXXABI_SRC}/include"
CXXFLAGS="${CXXFLAGS} -I${LIBUNWIND_SRC}/include"
CFLAGS="${CFLAGS} -I${LIBCXXABI_SRC}/include"
CFLAGS="${CFLAGS} -I${LIBUNWIND_SRC}/include"

for FILE in ${LIBCXXABI_SRC}/src/*.cpp; do
  echo "compile: ${FILE}"
  ${CXX} -c $CXXFLAGS $OPTIONS $FILE
done

if [ "${ENABLE_LIBUNWIND}" = "1" ]; then
  LIBUNWIND_FILES="$(find "${LIBUNWIND_SRC}/src" -name "*.cpp")"
  for FILE in ${LIBUNWIND_FILES}; do
    if [ "$(basename "${FILE}")" = "Unwind_AppleExtras.cpp" ]; then
      continue
    fi
    echo "compile: ${FILE}"
    ${CXX} -c $CXXFLAGS $OPTIONS $FILE
  done

  LIBUNWIND_FILES="$(find "${LIBUNWIND_SRC}/src" -name "*.c")"
  for FILE in ${LIBUNWIND_FILES}; do
    echo "compile: ${FILE}"
    ${CC} -c $CFLAGS $OPTIONS $FILE
  done

  LIBUNWIND_FILES="$(find "${LIBUNWIND_SRC}/src" -name "*.S")"
  for FILE in ${LIBUNWIND_FILES}; do
    echo "compile: ${FILE}"
    ${CC} -c $CFLAGS $OPTIONS $FILE
  done
fi

echo "link: ${OUTPUT_FULL}"
$CC -o "${OUTPUT_FULL}" *.o $LDFLAGS $CXXFLAGS

echo "installing ..."
mkdir -p "${OUT_DIR}/lib"
cp "${LIBCXXABI_OBJ}/${OUTPUT_FULL}" "${OUT_DIR}/lib"
(cd "${OUT_DIR}/lib"; ln -sf "${OUTPUT_FULL}" "${OUTPUT}.${OUTPUT_MAJOR}")
(cd "${OUT_DIR}/lib"; ln -sf "${OUTPUT_FULL}" "${OUTPUT}")

mkdir -p "${OUT_DIR}/include"
find "${LIBCXXABI_SRC}/include" -maxdepth 1 -name '*.h' -exec \
  cp {} "${OUT_DIR}/include" \;

rm -r "${LIBCXXABI_OBJ}"

echo done.
