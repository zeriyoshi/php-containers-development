ARG PLATFORM=${BUILDPLATFORM:-linux/amd64}

ARG DISTRO="bookworm"

ARG INSTALL_PACKAGES="gcc gdb"

ARG PHP_GIT_REF="master"

ARG USE_CLANG=""
ARG CC=""
ARG CXX=""
ARG CFLAGS="-fPIC -DZEND_TRACK_ARENA_ALLOC"
ARG LDFLAGS=""
ARG CONFIGURE_OPTIONS=""

FROM --platform=${PLATFORM} debian:${DISTRO}

ARG INSTALL_PACKAGES

ARG PHP_GIT_REF

ARG USE_CLANG
ARG CFLAGS
ARG LDFLAGS
ARG CONFIGURE_OPTIONS

ENV CFLAGS="${CFLAGS}"
ENV CPPFLAGS="${CFLAGS}"
ENV LDFLAGS="${LDFLAGS}"

RUN apt-get update \
 && apt-get install -y "git" "adduser" "sudo" "lsb-release" "curl" \
 && adduser --disabled-password --gecos "" "php" \
 && adduser "php" "sudo" \
 && echo "php ALL=(ALL) NOPASSWD:ALL" >> "/etc/sudoers" \
 && mkdir "/usr/src/php" \
 && chown "php" "/usr/src/php"

RUN apt-get update \
 && if test "x${USE_CLANG}" = "x"; then \
      apt-get install -y "gcc" "gdb"; \
    else \
      echo "deb http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${USE_CLANG} main" > "/etc/apt/sources.list.d/llvm.list" \
 &&   echo "deb-src http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-${USE_CLANG} main" >> "/etc/apt/sources.list.d/llvm.list" \
 &&   curl -fsSL "https://apt.llvm.org/llvm-snapshot.gpg.key" -o "/etc/apt/trusted.gpg.d/apt.llvm.org.asc" \
 &&   apt-get update \
 &&   apt-get install -y "clang-${USE_CLANG}" "llvm-${USE_CLANG}" "lldb-${USE_CLANG}" \
 &&   update-alternatives --install "/usr/bin/clang" clang "/usr/bin/clang-${USE_CLANG}" 100 \
 &&   update-alternatives --install "/usr/bin/clang++" clang++ "/usr/bin/clang++-${USE_CLANG}" 100 \
 &&   update-alternatives --install "/usr/bin/lldb" lldb "/usr/bin/lldb-${USE_CLANG}" 100; \
    fi

RUN if test "x${INSTALL_PACKAGES}" != "x"; then \
      apt-get update \
 &&   apt-get install -y ${INSTALL_PACKAGES}; \
    fi

USER php

RUN git clone --depth=1 --branch="${PHP_GIT_REF}" "https://github.com/php/php-src.git" "/usr/src/php" \
 && if test "x${USE_CLANG}" = "x"; then \
      export CC="gcc" \
 &&   export CXX="g++" \
 &&   export LD="ld"; \
    else \
      export CC="clang" \
 &&   export CXX="clang++"; \
    fi \
 && cd "/usr/src/php" \
 &&   sudo apt-get install -y "autoconf" "bison" "re2c" "pkg-config" "libxml2-dev" "libsqlite3-dev" "make" \
 &&   ./buildconf --force \
 &&   CFLAGS="${CFLAGS}" CPPFLAGS="${CPPFLAGS}" LDFLAGS="${LDFLAGS}" ./configure ${CONFIGURE_OPTIONS} --enable-option-checking=fatal \
 &&   make -j"$(nproc)" \
 && cd -

RUN cd "/usr/src/php" \
 &&   sudo make install || true \
 && cd -

WORKDIR "/usr/src/php"
