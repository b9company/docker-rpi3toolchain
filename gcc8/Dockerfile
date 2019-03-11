# -----------------------------------------------------------------------------
# Toolchain for Raspberry PI BCM2709 hardware. 
#
# This image is an upgrade from b9company/rpi3toolchain:stock image, which
# brings the features of the latest version of GCC to the PI.

ARG BINUTILS_VERSION=2.28
ARG GLIBC_VERSION=2.24
ARG GCC_VERSION=8.1.0

ARG ARCH=armv6
ARG TARGET=arm-linux-gnueabihf
ARG KERNEL=kernel7
ARG KERNEL_BRANCH=rpi-4.14.y
ARG INSTALL_DIR=/opt/rpi3toolchain
ARG DESTDIR=/build/rpi3toolchain

# Base image for build stage and final image.
FROM ubuntu:18.10 AS base
WORKDIR /build

# -----------------------------------------------------------------------------
# Build stage

FROM base AS build-binutils
ARG BINUTILS_VERSION
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
    tar xf binutils-${BINUTILS_VERSION}.tar.bz2

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

# Build GCC and Glibc. Use the stock compiler from b9company/rpi3toolchain:stock
# image. We do staged installs of GCC and Glibc, which will be copied over to
# their final location in a fresh image.

FROM b9company/rpi3toolchain:stock AS build-gcc
ARG GLIBC_VERSION
ARG GCC_VERSION
ARG ARCH
ARG TARGET
ARG INSTALL_DIR
ARG DESTDIR

RUN apt-get update && apt-get install -y \
      build-essential \
      git \
      texinfo \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    wget -q https://ftpmirror.gnu.org/glibc/glibc-${GLIBC_VERSION}.tar.bz2; \
    wget -q https://ftpmirror.gnu.org/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.gz; \
    tar xf glibc-${GLIBC_VERSION}.tar.bz2; \
    tar xf gcc-${GCC_VERSION}.tar.gz

# For MACHTYPE.
SHELL ["/bin/bash", "-c"]

WORKDIR /build/glibc
RUN set -eux; \
    /build/glibc-${GLIBC_VERSION}/configure --prefix=${INSTALL_DIR}/${TARGET} \
      --target=${TARGET} --with-arch=${ARCH} --with-fpu=vfp --with-float=hard \
      --host=${TARGET} --build=${MACHTYPE} --with-headers=${INSTALL_DIR}/${TARGET}/include \
      --disable-multilib libc_cv_forced_unwind=yes; \
    make -j8; \
    make install DESTDIR=${DESTDIR}

WORKDIR /build/gcc-${GCC_VERSION}
RUN contrib/download_prerequisites
WORKDIR /build/gcc
RUN set -eux; \
    /build/gcc-${GCC_VERSION}/configure --prefix=${INSTALL_DIR} \
      --target=${TARGET} --enable-languages=c,c++,fortran \
      --with-arch=armv6 --with-fpu=vfp --with-float=hard --disable-multilib; \
    make -j8; \
    make install DESTDIR=${DESTDIR}

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
ARG DESTDIR
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
COPY --from=build-binutils ${INSTALL_DIR} ${INSTALL_DIR}
COPY --from=build-gcc ${DESTDIR}${INSTALL_DIR} ${INSTALL_DIR}
ENV PATH=${PATH}:${INSTALL_DIR}/bin
