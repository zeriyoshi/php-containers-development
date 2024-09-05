PHP_GIT_REF ?= master
CONFIGURE_OPTIONS ?=
IMAGE_TAG ?= php-container-build
PLATFORM ?= $(shell docker version --format '{{.Server.Os}}/{{.Server.Arch}}')
WAIT_SECS ?= 30
USE_NATIVE_DOCKER ?=
DISTRO ?= unstable

# Due to Sanitizer builds requiring privileges, use DinD.
up:
	docker container run \
	  --rm \
	  --platform $(PLATFORM) \
	  --name php-container-dockerd \
	  --cap-add SYS_ADMIN \
	  --security-opt seccomp:unconfined \
	  --privileged \
	  --detach \
	  --publish 2376:2376 \
	  --volume $(shell pwd)/certs:/certs \
	  docker:dind
	sleep $(WAIT_SECS)

down:
	docker container kill php-container-dockerd
	rm -rf $(shell pwd)/certs

clean:
	docker images $(IMAGE_TAG) --format '{{.ID}}' | xargs docker image rm

all: gcc debug gcov valgrind clang msan asan ubsan

define docker_build
	$(if $(USE_NATIVE_DOCKER),\
		docker build \
		  --build-arg PLATFORM="$(PLATFORM)" \
		  --build-arg DISTRO="${DISTRO}" \
		  --build-arg PHP_GIT_REF="$(PHP_GIT_REF)" \
		  --tag php-container:${1}-$(PHP_GIT_REF) \
		  --tag $(IMAGE_TAG) \
		  --build-arg CONFIGURE_OPTIONS="$(2)" \
		  $(3) \
		  . \
		, \
		DOCKER_HOST=tcp://localhost:2376 \
		DOCKER_CERT_PATH=$(shell pwd)/certs/client \
		DOCKER_TLS_VERIFY=1 \
		  docker build \
		    --build-arg PLATFORM="$(PLATFORM)" \
			--build-arg DISTRO="${DISTRO}" \
		    --build-arg PHP_GIT_REF="$(PHP_GIT_REF)" \
		    --tag php-container:${1}-$(PHP_GIT_REF) \
		    --tag $(IMAGE_TAG) \
		    --build-arg CONFIGURE_OPTIONS="$(2)" \
		    $(3) \
		    . && \
		(DOCKER_HOST=tcp://localhost:2376 \
		DOCKER_CERT_PATH=$(shell pwd)/certs/client \
		DOCKER_TLS_VERIFY=1 \
		docker image save $(IMAGE_TAG)) | docker image load \
	)
endef

debug:
	$(call docker_build,$@,--enable-debug $(CONFIGURE_OPTIONS),)

gcov:
	$(call docker_build,$@,--enable-debug --without-pcre-jit --disable-opcache-jit --enable-gcov $(CONFIGURE_OPTIONS),)

valgrind:
	$(call docker_build,$@,--enable-debug --without-pcre-jit --disable-opcache-jit --with-valgrind $(CONFIGURE_OPTIONS),--build-arg INSTALL_PACKAGES="gcc gdb valgrind")

msan:
	$(call docker_build,$@,--enable-debug --without-pcre-jit --disable-opcache-jit --enable-memory-sanitizer $(CONFIGURE_OPTIONS),--build-arg INSTALL_PACKAGES="clang lldb" --build-arg CC="clang" --build-arg CXX="clang++")

asan:
	$(call docker_build,$@,--enable-debug --without-pcre-jit --disable-opcache-jit --enable-address-sanitizer $(CONFIGURE_OPTIONS),--build-arg INSTALL_PACKAGES="clang lldb" --build-arg CC="clang" --build-arg CXX="clang++")

ubsan:
	$(call docker_build,$@,--enable-debug --without-pcre-jit --disable-opcache-jit --enable-undefined-sanitizer $(CONFIGURE_OPTIONS),--build-arg INSTALL_PACKAGES="clang lldb" --build-arg CC="clang" --build-arg CXX="clang++")

.PHONY: up down all clean debug gcov valgrind msan asan ubsan
