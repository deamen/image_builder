.ONESHELL:   # Enable single-shell mode for all recipes in this Makefile
# Makefile for image_builder

# Detect WSL and set PACKER accordingly
ifeq ($(shell grep -i microsoft /proc/version 2>/dev/null),)
PACKER=/usr/bin/packer
else
PACKER=packer.exe
endif

.PHONY: all qemu.alpine

qemu.alpine:
	cd qemu/alpine
	$(PACKER) build  -var build_password='$(shell pwgen --capitalize --numerals --symbols 20 1)' -on-error=ask -force -only qemu.alpine .
