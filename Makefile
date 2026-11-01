.ONESHELL:   # Enable single-shell mode for all recipes in this Makefile
# Makefile for image_builder

# Detect WSL and set PACKER accordingly
ifeq ($(shell grep -i microsoft /proc/version 2>/dev/null),)
PACKER=/usr/bin/packer
else
PACKER=packer.exe
endif

.PHONY: container qemu qemu.alpine container.fedora-init container.fedora-ansible container.fedora-dst

CONTAINER_TARGETS := container.fedora-init container.fedora-ansible
QEMU_TARGETS := qemu.alpine

container:
	@for target in $(CONTAINER_TARGETS); do \
		$(MAKE) $$target; \
	done

qemu:
	@for target in $(QEMU_TARGETS); do \
		$(MAKE) $$target; \
	done

qemu.alpine:
	cd qemu/alpine
	$(PACKER) build  -var build_password='$(shell pwgen --capitalize --numerals --symbols 20 1)' -on-error=ask -force -only qemu.alpine .

container.fedora-init:
	cd container/fedora && ./buildah_fedora-init.sh

container.fedora-ansible:
	cd container/fedora && ./buildah_fedora-ansible.sh

# fedora-dst is built on the local fedora-init-$(ARCH) image (see INIT_IMAGE in
# fedora_vars.sh), so build that first. Not in CONTAINER_TARGETS since it pulls
# several GB of game files.
container.fedora-dst: container.fedora-init
	cd container/fedora && ./buildah_fedora-dst.sh
