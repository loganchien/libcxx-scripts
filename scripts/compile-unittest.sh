#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

# Failed test case blacklist
XFAIL_RUN=""
XFAIL_COMPILE=""

# Compilation flags
CXXFLAGS="-nostdinc++
          -std=c++11
          -isystem ${OUT_DIR}/include
          -isystem ${OUT_DIR}/include/c++/v1"

CXXFLAGS="${CXXFLAGS} -O0 -g"

if [ -e "${OUT_DIR}/lib/libunwind.so" ]; then
LDFLAGS="-L${OUT_DIR}/lib -nodefaultlibs
         -lc++ -lpthread -lc++abi -lunwind -lm -lc -lgcc_s -lgcc"
else
LDFLAGS="-L${OUT_DIR}/lib -nodefaultlibs
         -lc++ -lpthread -lc++abi -lm -lc -lgcc_s -lgcc"
fi


#-------------------------------------------------------------------------------
# Target configuration
#-------------------------------------------------------------------------------

case "${CROSS_COMPILING}" in
arm)
  # Find cross compiling system include path.
  SYSTEM_INCLUDE="/usr/arm-linux-gnueabihf/include"
  if [ -d "${SYSTEM_INCLUDE}" ]; then
    CXXFLAGS="${CXXFLAGS} -isystem ${SYSTEM_INCLUDE}"
  fi

  # Cross compiling flag
  case "${CC}" in
    *clang*)
    CXXFLAGS="-target arm-linux-gnueabihf ${CXXFLAGS}"
    LDFLAGS="-target arm-linux-gnueabihf ${LDFLAGS}"
    ;;
  esac
  ;;
esac


#-------------------------------------------------------------------------------
# Configuration test
#-------------------------------------------------------------------------------

# check for __cxa_thread_atexit_impl()
set +e

cat > test.cpp <<__EOF__
extern "C" int __cxa_thread_atexit_impl(void (*dtor)(void *), void *, void *);
int main() {
  __cxa_thread_atexit_impl(0, 0, 0);
}
__EOF__

${CXX} ${CFLAGS} ${CXXFLAGS} test.cpp -o /dev/null > /dev/null 2>&1

if [ $? != 0 ]; then
  XFAIL_COMPILE="${XFAIL_COMPILE} cxa_thread_atexit_test"
fi

rm test.cpp a.out > /dev/null 2>&1

set -e


#-------------------------------------------------------------------------------
# Compile the test cases
#-------------------------------------------------------------------------------

# Remove existing test case output directory.
if [ -d "${LIBCXXABI_UNITTEST_OUT}" ]; then
  rm -rf "${LIBCXXABI_UNITTEST_OUT}"
fi
mkdir -p "${LIBCXXABI_UNITTEST_OUT}"

# Filter out ${XFAIL_COMPILE}
srcs="$(ls "${LIBCXXABI_SRC}/test" | grep '.*\.cpp')"
for i in ${XFAIL_COMPILE}; do
  srcs="$(echo "${srcs}" | grep -v "$i")"
done

for src in ${srcs}; do
  src="${LIBCXXABI_SRC}/test/${src}"
  exe="$(basename "${src/.cpp/}")"
  echo "compiling ${exe} ..."
  ${CXX} -o "${LIBCXXABI_UNITTEST_OUT}/${exe}" ${CXXFLAGS} ${LDFLAGS} ${src}
done

# Add libunwind test
if [ "${ENABLE_LIBUNWIND}" = 1 -a -d "${LIBCXXABI_SRC}/test/Unwind" ]; then
  unw_srcs="$(ls "${LIBCXXABI_SRC}/test/Unwind" | grep '.*\.cpp')"
  for i in ${XFAIL_COMPILE}; do
    unw_srcs="$(echo "${unw_srcs}" | grep -v "$i")"
  done

  for src in ${unw_srcs}; do
    src="${LIBCXXABI_SRC}/test/Unwind/${src}"
    exe="$(basename "${src/.cpp/}")"
    echo "compiling ${exe} ..."
    ${CXX} -o "${LIBCXXABI_UNITTEST_OUT}/${exe}" ${CXXFLAGS} ${LDFLAGS} ${src}
  done
fi


#-------------------------------------------------------------------------------
# Create the scripts to run all test cases
#-------------------------------------------------------------------------------

RUN_ALL_SCRIPT="${LIBCXXABI_UNITTEST_OUT}/run-all.sh"

# Remove the existing run-all.sh
if [ -e "${RUN_ALL_SCRIPT}" ]; then
  rm "${RUN_ALL_SCRIPT}"
fi

# Filter out ${XFAIL_RUN}
exes="$(cd "${LIBCXXABI_UNITTEST_OUT}"; ls)"
for i in ${XFAIL_RUN}; do
  exes="$(echo "${exes}" | grep -v "$i")"
done

cat >> "${RUN_ALL_SCRIPT}" <<__EOF__
#!/bin/bash -e
SCRIPT_DIR="\$(cd "\$(dirname "\$0")"; pwd)"
cd "\${SCRIPT_DIR}"

TESTS="${exes}"
for i in \${TESTS}; do
  echo "Running \$i ..."
  LD_LIBRARY_PATH="\${SCRIPT_DIR}/../lib" ./\$i > /dev/null 2>&1
done

echo

XFAIL_COMPILE="${XFAIL_COMPILE}"
if [ ! -z "${XFAIL_COMPILE}" ]; then
  echo "---> NOT COMPILED: ${XFAIL_COMPILE}"
fi

XFAIL_RUN="${XFAIL_RUN}"
if [ ! -z "${XFAIL_RUN}" ]; then
  echo "---> NOT RUN: ${XFAIL_RUN}";
fi

echo "===> PASSING ALL TESTS"
__EOF__

chmod +x "${RUN_ALL_SCRIPT}"
