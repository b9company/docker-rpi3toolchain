include mk/docker/defines.mk

dir := stock
include $(dir)/rules.mk
dir := gcc8
include $(dir)/rules.mk

.PHONY: all
all: $(BUILD)
