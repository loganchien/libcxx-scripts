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

RUN_ALL_SCRIPT="${LIBCXXABI_UNITTEST_OUT}/run-all.sh"

if [ -e "${RUN_ALL_SCRIPT}" ]; then
  rm "${RUN_ALL_SCRIPT}"
fi

exes="$(cd "${LIBCXXABI_UNITTEST_OUT}"; ls)"

echo "#!/bin/bash -e
SCRIPT_DIR=\"\$(cd \"\$(dirname \"\$0\")\"; pwd)\"
cd \"\${SCRIPT_DIR}\"

TESTS=\"${exes}\"
for i in \${TESTS}; do
  echo \"Running \$i ...\"
  LD_LIBRARY_PATH="\${SCRIPT_DIR}/../lib" ./\$i > /dev/null 2>&1
done

echo \"PASSING ALL TESTS\"" > "${RUN_ALL_SCRIPT}"

chmod +x "${RUN_ALL_SCRIPT}"
