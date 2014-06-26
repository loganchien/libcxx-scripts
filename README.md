Build script for libcxx+libcxxabi
=================================

This is the build script to build libcxx with libcxxabi for x86-64 and arm.
These scripts are created for my libcxxabi ARM EHABI support development.


Dependencies
------------

Before you can run the script, please make sure that you have clang and
clang++ in your $PATH.  It is suggested to have 3.5 at least.

Besides, you will need cmake to build libc++ properly.


Build for x86
-------------

To build all libraries from scratch for x86, you can use:

    $ ./scripts/compile-all.sh

If everything works fine, then you can run libcxxabi unit tests with:

    $ ./out/unittest/run-all.sh

To clean the generated files, you can run:

    $ ./scripts/clean.sh

If you wish to build only one library, you can run following commands
to build libcxxabi, libcxx, libcxxabi unit tests, respectively,

    $ ./scripts/compile-abi.sh
    $ ./scripts/compile-libcxx.sh
    $ ./scripts/compile-unittest.sh


Build for ARM
-------------

To cross compile the libraries for ARM, you have to export following
environment variable first:

    $ export CROSS_COMPILING=arm

To build all libraries from scratch for ARM, you can use:

    $ CROSS_COMPILING=arm ./scripts/compile-all.sh

To build all libraries from scratch for ARM with libunwind, you can use:

    $ CROSS_COMPILING=arm ENABLE_LIBUNWIND=1 ./scripts/compile-all.sh

The compiled binaries is in the `out-arm` directories.  You can copy them to
your ARM testing device.  Besides, you can run the libcxxabi unit test with

    $ ./out-arm/unittests/run-all.sh

To clean the generated files, you can run:

    $ ./scripts/clean.sh

If you wish to build only one library, you can run following commands
to build libcxxabi, libcxx, libcxxabi unit tests, respectively,

    $ CROSS_COMPILING=arm ./scripts/compile-abi.sh
    $ CROSS_COMPILING=arm ./scripts/compile-libcxx.sh
    $ CROSS_COMPILING=arm ./scripts/compile-unittest.sh
