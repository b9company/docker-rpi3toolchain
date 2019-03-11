include mk/header.mk

$(d)/GCC_VERSION := 8.3.0

$(d)/DOCKER_IMAGE := b9company/rpi3toolchain:$($(d)/GCC_VERSION)
$(d)/DOCKER_BUILD_ARGS := --build-arg GCC_VERSION=$($(d)/GCC_VERSION)

include mk/docker/rules.mk

include mk/footer.mk

