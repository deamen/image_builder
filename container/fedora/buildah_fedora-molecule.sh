#!/bin/bash
set -e

# A small target image for molecule tests: fedora-init plus only what ansible needs to manage it.
# Keep it small: don't add anything molecule doesn't need.
# sudo is needed for become; python3-dnf and python3-libdnf5 let the package/dnf modules work
# with both dnf4 and dnf5; util-linux provides runuser, which tests use to run commands as another user
MOLECULE_PACKAGES="sudo python3-dnf python3-libdnf5 util-linux"

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-molecule}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}

# Build on the locally built fedora-init image so systemd runs as PID 1 (molecule tests can then
# manage services). fedora-init is not published, so `make container.fedora-init` must run first.
# The /sbin/init entrypoint, empty CMD and SIGRTMIN+3 stop signal are inherited from it.
ctr=$(eval "$INIT_CONTAINER")

set_container_annotations "$ctr"

add_packages $ctr ${MOLECULE_PACKAGES}

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
