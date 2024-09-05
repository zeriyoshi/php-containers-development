ARG PLATFORM=${BUILDPLATFORM:-linux/amd64}

ARG DISTRO="unstable"

ARG INSTALL_PACKAGES="gcc gdb"

ARG PHP_GIT_REF="master"

ARG CC="gcc"
ARG CXX="g++"
ARG CFLAGS="-O0 -fPIC"
ARG LDFLAGS="-O0"
ARG CONFIGURE_OPTIONS=""

FROM --platform=${PLATFORM} debian:${DISTRO}

ARG INSTALL_PACKAGES

ARG PHP_GIT_REF

ARG CC
ARG CXX
ARG CFLAGS
ARG LDFLAGS
ARG CONFIGURE_OPTIONS

ENV CFLAGS="${CFLAGS}"
ENV CPPFLAGS="${CFLAGS}"
ENV LDFLAGS="${LDFLAGS}"

RUN apt-get update \
 && apt-get install -y "git" \
 && apt-get install -y ${INSTALL_PACKAGES} \
 && git clone --depth=1 --branch="${PHP_GIT_REF}" "https://github.com/php/php-src.git" "/usr/src/php" \
 && cd "/usr/src/php" \
 &&   apt-get install -y "autoconf" "bison" "re2c" "pkg-config" "libxml2-dev" "libsqlite3-dev" "make" \
 &&   ./buildconf --force \
 &&   CC="${CC}" CXX="${CXX}" CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" ./configure ${CONFIGURE_OPTIONS} --enable-option-checking=fatal \
 &&   make -j"$(nproc)" \
 &&   make install \
 && cd -
