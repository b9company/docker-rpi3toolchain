# -----------------------------------------------------------------------------
# Toolchain for Raspberry PI BCM2709 hardware. 
#
# This image ships with the same versions of GCC, Binutils, and Glibc, as the
# ones reported from the Raspbian distribution. We take care of using the exact
# same Glibc version, built with the exact same compiler version, as the ones
# from the Raspbian distribution to ensure proper integration with the OS.
#
# Built with:
# $ ld -v
# GNU ld (GNU Binutils for Raspbian) 2.28
ARG BINUTILS_VERSION=2.28
# $ ldd --version
# ldd (Debian GLIBC 2.24-11+deb9u3) 2.24
ARG GLIBC_VERSION=2.24
# $ gcc --version
# gcc (Raspbian 6.3.0-18+rpi1+deb9u1) 6.3.0 20170516
ARG GCC_VERSION=6.3.0

ARG ARCH=armv6
ARG TARGET=arm-linux-gnueabihf
ARG KERNEL=kernel7
ARG KERNEL_BRANCH=rpi-4.14.y
ARG INSTALL_DIR=/opt/rpi3toolchain

# Base image for build stage and final image.
FROM ubuntu:18.10 AS base
WORKDIR /build

# -----------------------------------------------------------------------------
# Build stage

FROM base as build
ARG BINUTILS_VERSION
ARG GLIBC_VERSION
ARG GCC_VERSION
ARG ARCH
ARG TARGET
ARG KERNEL
ARG KERNEL_BRANCH
ARG INSTALL_DIR

RUN apt-get update && apt-get install -y \
      bison \
      build-essential \
      file \
      gawk \
      git \
      texinfo \
      wget \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    git clone --branch ${KERNEL_BRANCH} --depth=1 https://github.com/raspberrypi/linux; \
    wget -q https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VERSION}.tar.bz2; \
    wget -q https://ftpmirror.gnu.org/glibc/glibc-${GLIBC_VERSION}.tar.bz2; \
    wget -q https://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz; \
    tar xf binutils-${BINUTILS_VERSION}.tar.bz2; \
    tar xf glibc-${GLIBC_VERSION}.tar.bz2; \
    tar xf gcc-${GCC_VERSION}.tar.gz

# Build and install the cross-assembler, cross-linker, and other tools.
WORKDIR /build/binutils
RUN set -eux; \
    /build/binutils-${BINUTILS_VERSION}/configure --prefix=${INSTALL_DIR} \
      --target=${TARGET} --with-arch=${ARCH} --with-fpu=vfp --with-float=hard \
      --disable-multilib; \
    make -j8; \
    make install

# Install the kernel headers in the target system root.
# See: https://www.raspberrypi.org/documentation/linux/kernel/building.md
WORKDIR /build/linux
RUN make ARCH=arm KERNEL=${KERNEL} INSTALL_HDR_PATH=${INSTALL_DIR}/${TARGET} headers_install

ENV PATH=${PATH}:${INSTALL_DIR}/bin

# Build GCC and Glibc. Parts of GCC depend on parts of Glibc already being
# built, and vice versa. Both packages can’t be built in a single step, so we go
# back and forth between the two packages and build their components in a way
# that satisfies their dependencies.
# Ref: https://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/

# For MACHTYPE.
SHELL ["/bin/bash", "-c"]

# Build and install C and C++ cross-compilers only.
WORKDIR /build/gcc-${GCC_VERSION}
RUN contrib/download_prerequisites
RUN sed -i '1474s/xloc.file ==/xloc.file[0] ==/' gcc/ubsan.c
WORKDIR /build/gcc
RUN set -eux; \
    /build/gcc-${GCC_VERSION}/configure --prefix=${INSTALL_DIR} \
      --target=${TARGET} --with-arch=${ARCH} --with-fpu=vfp --with-float=hard \
      --enable-languages=c,c++,fortran --disable-multilib; \
    make -j8 all-gcc; \
    make install-gcc

# Build and install standard C Library headers and startup files with C
# cross-compiler. Create dummy files required for when building the compiler
# support library, which ultimately will be replaced when completing building
# the standard C library.
WORKDIR /build/glibc
RUN set -eux; \
    /build/glibc-${GLIBC_VERSION}/configure --prefix=${INSTALL_DIR}/${TARGET} \
      --target=${TARGET} --with-arch=${ARCH} --with-fpu=vfp --with-float=hard \
      --host=${TARGET} --build=${MACHTYPE} --with-headers=${INSTALL_DIR}/${TARGET}/include \
      --disable-multilib libc_cv_forced_unwind=yes; \
    make install-bootstrap-headers=yes install-headers; \
    make -j8 csu/subdir_lib; \
    install csu/crt1.o csu/crti.o csu/crtn.o ${INSTALL_DIR}/${TARGET}/lib; \
    ${TARGET}-gcc -nostdlib -nostartfiles -shared -x c /dev/null \
      -o ${INSTALL_DIR}/${TARGET}/lib/libc.so; \
    touch ${INSTALL_DIR}/${TARGET}/include/gnu/stubs.h

# Build the compiler support library, which contains some C++ exception handling
# boilerplate code, among other things. This library depends on the startup
# files installed previously. The library itself is needed when completing
# building the standard C library.
WORKDIR /build/gcc
RUN set -eux; \
    make -j8 all-target-libgcc; \
    make install-target-libgcc

# Finish off building the standard C library.
WORKDIR /build/glibc
RUN set -eux; \
    make -j8; \
    make install

# Finish off building GCC. This builds the standard C++ library, which depends
# on the freshly built standard C library.
WORKDIR /build/gcc
RUN set -eux; \
    make -j8; \
    make install

# -----------------------------------------------------------------------------
# Final image

FROM base
ARG BINUTILS_VERSION
ARG GLIBC_VERSION
ARG GCC_VERSION
ARG ARCH
ARG TARGET
ARG KERNEL
ARG KERNEL_BRANCH
ARG INSTALL_DIR
LABEL maintainer="the B9 Company <lab@b9company.fr>" \
      description="Toolchain for Raspberry Pi BCM2709 hardware" \
      binutils_version="${BINUTILS_VERSION}" \
      glibc_version="${GLIBC_VERSION}" \
      gcc_version="${GCC_VERSION}" \
      hardware="${ARCH}" \
      target="${TARGET}" \
      kernel="${KERNEL}" \
      kernel_branch="${KERNEL_BRANCH}"
RUN apt-get update && apt-get install -y \
      bison \
      file \
      gawk \
      make \
      patch \
      wget \
      xz-utils \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build ${INSTALL_DIR} ${INSTALL_DIR}
ENV PATH=${PATH}:${INSTALL_DIR}/bin
