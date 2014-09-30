#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
source "${SCRIPT_DIR}/config.sh"

CXXFLAGS="-nostdinc++
          -std=c++11
          -isystem ${OUT_DIR}/include
          -isystem ${OUT_DIR}/include/c++/v1"

# debug flags
CXXFLAGS="${CXXFLAGS} -O0 -g"

LDFLAGS="-L${OUT_DIR}/lib -nodefaultlibs
         -lc++ -lpthread -lc++abi -lm -lc -lgcc_s -lgcc"

if [ "${CROSS_COMPILING}" = "arm" ]; then
  # HACK: find cross compiling system include path
  SYSTEM_INCLUDE="/usr/arm-linux-gnueabihf/include"
  if [ -d "${SYSTEM_INCLUDE}" ]; then
    CXXFLAGS="${CXXFLAGS} -isystem ${SYSTEM_INCLUDE}"
  fi

  CXXFLAGS="-target arm-linux-gnueabihf ${CXXFLAGS}"
  LDFLAGS="-target arm-linux-gnueabihf ${LDFLAGS}"
fi

# Compile the test cases

if [ -d "${LIBCXXABI_UNITTEST_OUT}" ]; then
  rm -rf "${LIBCXXABI_UNITTEST_OUT}"
fi
mkdir -p "${LIBCXXABI_UNITTEST_OUT}"

for src in ${LIBCXXABI_SRC}/test/*.cpp; do
  echo "${src}"
  exe="$(basename "${src/.cpp/}")"
  ${CXX} -o "${LIBCXXABI_UNITTEST_OUT}/${exe}" ${CXXFLAGS} ${LDFLAGS} ${src}
done

# Create the scripts to run all test cases

if [ "${CROSS_COMPILING}" = "arm" ]; then
  # FIXME: Remove this after the backtrace_test has been fixed.
  DISABLED_TESTS="backtrace_test"
else
  DISABLED_TESTS=""
fi

RUN_ALL_SCRIPT="${LIBCXXABI_UNITTEST_OUT}/run-all.sh"

if [ -e "${RUN_ALL_SCRIPT}" ]; then
  rm "${RUN_ALL_SCRIPT}"
fi

exes="$(cd "${LIBCXXABI_UNITTEST_OUT}"; ls)"

# Filter out the disabled unit test
for i in ${DISABLED_TESTS}; do
  exes="$(echo "${exes}" | grep -v "$i")"
done

echo "#!/bin/bash -e
SCRIPT_DIR=\"\$(cd \"\$(dirname \"\$0\")\"; pwd)\"
cd \"\${SCRIPT_DIR}\"

TESTS=\"${exes}\"
for i in \${TESTS}; do
  echo \"Running \$i ...\"
  LD_LIBRARY_PATH="\${SCRIPT_DIR}/../lib" ./\$i > /dev/null 2>&1
done

echo

DISABLED_TESTS=\"${DISABLED_TESTS}\"
if [ ! -z \"${DISABLED_TESTS}\" ]; then
  echo \"---> DISABLED: ${DISABLED_TESTS}\";
fi

echo \"===> PASSING ALL TESTS\"

echo" > "${RUN_ALL_SCRIPT}"

chmod +x "${RUN_ALL_SCRIPT}"
