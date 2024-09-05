ARG PLATFORM=${BUILDPLATFORM:-linux/amd64}

ARG DISTRO="unstable"

ARG INSTALL_PACKAGES="gcc gdb"

ARG PHP_GIT_REF="master"

ARG CC="gcc"
ARG CXX="g++"
ARG CFLAGS="-O0 -fPIC"
ARG LDFLAGS="-O0"
ARG CONFIGURE_OPTIONS=""

ARG USE_ZEND_ALLOC=0
ARG USE_TRACKED_ALLOC=1
ARG ZEND_DONT_UNLOAD_MODULES=1

FROM --platform=${PLATFORM} debian:${DISTRO}

ARG INSTALL_PACKAGES

ARG PHP_GIT_REF

ARG CC
ARG CXX
ARG CFLAGS
ARG LDFLAGS
ARG CONFIGURE_OPTIONS

ARG USE_ZEND_ALLOC
ARG USE_TRACKED_ALLOC
ARG ZEND_DONT_UNLOAD_MODULES

ENV USE_ZEND_ALLOC=${USE_ZEND_ALLOC}
ENV USE_TRACKED_ALLOC=${USE_TRACKED_ALLOC}
ENV ZEND_DONT_UNLOAD_MODULES=${ZEND_DONT_UNLOAD_MODULES}

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
#  &&  SKIP_IO_CAPTURE_TESTS=1 \
#      SKIP_ASAN=1 \
#      SKIP_ONLINE_TESTS=1 \
#      SKIP_SLOW_TESTS=1 \
#      TEST_PHP_ARGS="-q --show-diff -j$(nproc)" \
#       make test \
 &&   make install \
 && cd -
