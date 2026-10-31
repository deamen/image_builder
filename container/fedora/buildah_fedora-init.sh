#!/bin/bash
set -e

INIT_PACKAGES="systemd procps-ng"

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-init}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}

# Create a new container from the fedora base image with specified architecture
ctr=$(eval "$BASE_CONTAINER")

set_container_annotations "$ctr"

add_packages $ctr ${INIT_PACKAGES}

# Use ENTRYPOINT rather than CMD so systemd always starts as PID 1, even if the
# container runtime passes its own command (that command becomes an argument to
# init instead of replacing it). Clear the base image's CMD (/bin/bash) so it
# isn't passed to init by default.
buildah config --entrypoint '["/sbin/init"]' "$ctr"
buildah config --cmd '' "$ctr"

# SIGRTMIN+3 is what systemd-as-PID1 treats as a clean shutdown request;
# without this, `podman/docker stop` sends SIGTERM, which systemd instead
# interprets as a request to re-exec/soft-reboot PID 1.
buildah config --stop-signal SIGRTMIN+3 "$ctr"

# Mask unnecessary systemd units
buildah run "$ctr" systemctl mask \
    systemd-remount-fs.service \
    dev-hugepages.mount \
    sys-fs-fuse-connections.mount \
    systemd-logind.service \
    getty.target \
    console-getty.service \
    systemd-udev-trigger.service \
    systemd-udevd.service \
    systemd-random-seed.service

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
