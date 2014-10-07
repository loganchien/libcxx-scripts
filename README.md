Build script for libcxx+libcxxabi
=================================

This is the build script to build libcxx with libcxxabi for x86-64 and arm.
These scripts are created for my libcxxabi ARM EHABI support development.


Dependencies
------------

These scripts are tested under Debian Wheezy and Ubuntu 14.04 (host build).
You will might need some modification for other platforms or toolchains.

You will need `bintuils`, `gcc`, `g++`, `cmake`, and `clang` to build the
library.  The version of clang should be **3.5** or newer.

### Debian Wheezy

Add following line to `/etc/apt/sources.list`:

    # Emdebian for cross-compiling gcc toolchain
    deb http://ftp.uk.debian.org/emdebian/toolchains unstable main

    # LLVM apt prebuilt binary
    deb http://llvm.org/apt/wheezy/ llvm-toolchain-wheezy main
    deb-src http://llvm.org/apt/wheezy/ llvm-toolchain-wheezy main

Update the local APT database:

    $ sudo apt-get update

Install the dependencies:

    $ sudo apt-get install binutils clang-3.5 cmake gcc make

To cross-compile for ARM, install following dependencies as well:

    $ sudo apt-get install binutils-multiarch \
                           gcc-4.7-arm-linux-gnueabihf \
                           g++-4.7-arm-linux-gnueabihf

### Ubuntu 14.04

Build clang 3.5: You have to build your own copy of clang 3.5 from the official
LLVM 3.5 source code.  The `clang-3.5` package from Ubuntu APT repository won't
work.

Update the local APT database:

    $ sudo apt-get update

Install the dependencies:

    $ sudo apt-get install binutils cmake gcc g++ make

To cross-compile for ARM, install the following dependencies:

    $ sudo apt-get install binutils-multiarch \
                           gcc-4.7-arm-linux-gnueabihf \
                           g++-4.7-arm-linux-gnueabihf

NOTE: Although I can compile the libraries successfully, but I can't run the
output executables because I don't have ARM Ubuntu installation.  It is
suggested to cross-compile with Debian Wheezy instead.


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

To build all libraries from scratch for ARM with libunwind, you can use:

    $ CROSS_COMPILING=arm ENABLE_LIBUNWIND=1 ./scripts/compile-all.sh

The compiled binaries are in the `out-arm` directory.  You can copy them to
your ARM testing device.  Besides, you can run the libcxxabi unit test with

    $ ./out-arm/unittests/run-all.sh

To clean the generated files, you can run:

    $ ./scripts/clean.sh

If you wish to build only one library, you can run following commands
to build libcxxabi, libcxx, libcxxabi unit tests, respectively,

    $ CROSS_COMPILING=arm ENABLE_LIBUNWIND=1 ./scripts/compile-abi.sh
    $ CROSS_COMPILING=arm ENABLE_LIBUNWIND=1 ./scripts/compile-libcxx.sh
    $ CROSS_COMPILING=arm ENABLE_LIBUNWIND=1 ./scripts/compile-unittest.sh

To cross-compile your own program with libc++ and libc++abi:

    $ clang++ -target arm-linux-gnueabihf \
              -isystem out-arm/include \
              -isystem out-arm/include/c++/v1 \
              -isystem /usr/arm-linux-gnueabihf/include \
              -Lout-arm/lib \
              -lc++ -lpthread -lc++abi -lm -lc -lgcc_s -lgcc \
              your_source_file.cpp
