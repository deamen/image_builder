#!/bin/bash
set -e

# openssh-clients is needed for ansible to connect to remote hosts
ANSIBLE_PACKAGES="ansible ansible-lint openssh-clients pre-commit pipx git sudo"
ANSIBLE_PIP_PACKAGES="detect-secrets"
# https://github.com/schpet/linear-cli
LINEAR_CLI_VERSION=${LINEAR_CLI_VERSION:-v3.1.0}

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-ansible}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}
# Non-root user the container runs as (AUTHORS is the image label, not a user)
CONTAINER_USER=${CONTAINER_USER:-builder}

# Create a new container from the fedora-minimal image with specified architecture
ctr=$(eval "$MINIMAL_CONTAINER")

set_container_annotations "$ctr"

add_packages $ctr ${ANSIBLE_PACKAGES}

# Install linear-cli from the GitHub release. Download and verify on the host,
# since fedora-minimal has no tar/xz to unpack the .tar.xz archive.
case "$ARCH" in
    amd64) LINEAR_CLI_ARCH=x86_64 ;;
    arm64) LINEAR_CLI_ARCH=aarch64 ;;
    *) echo "Error: linear-cli is not available for ARCH=${ARCH}" >&2; exit 1 ;;
esac
LINEAR_CLI_TARBALL="linear-${LINEAR_CLI_ARCH}-unknown-linux-gnu.tar.xz"
LINEAR_CLI_URL="https://github.com/schpet/linear-cli/releases/download/${LINEAR_CLI_VERSION}/${LINEAR_CLI_TARBALL}"
linear_tmp=$(mktemp -d)
trap 'rm -rf "$linear_tmp"' EXIT
curl -sfL -o "${linear_tmp}/${LINEAR_CLI_TARBALL}" "$LINEAR_CLI_URL"
curl -sfL -o "${linear_tmp}/${LINEAR_CLI_TARBALL}.sha256" "${LINEAR_CLI_URL}.sha256"
(cd "$linear_tmp" && sha256sum -c "${LINEAR_CLI_TARBALL}.sha256")
tar -xJf "${linear_tmp}/${LINEAR_CLI_TARBALL}" -C "$linear_tmp" --strip-components=1
buildah copy --chmod 0755 "$ctr" "${linear_tmp}/linear" /usr/local/bin/linear

# Add ~/.local/bin to PATH for all users
buildah run "$ctr" sh -c "echo 'export PATH=\$PATH:~/.local/bin' > /etc/profile.d/user_home_local_bin.sh"
buildah run "$ctr" chmod 0644 /etc/profile.d/user_home_local_bin.sh

# Create default user and allow passwordless sudo
buildah run "$ctr" useradd -m "${CONTAINER_USER}"
buildah run "$ctr" sh -c "echo '${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CONTAINER_USER}"
buildah run "$ctr" chmod 0440 /etc/sudoers.d/${CONTAINER_USER}

configure_git_prompt $ctr "${CONTAINER_USER}"

# Set the default user and working directory for the container
buildah config --user "${CONTAINER_USER}" "$ctr"
buildah config --workingdir "/home/${CONTAINER_USER}" "$ctr"

install_pipx_packages $ctr ${ANSIBLE_PIP_PACKAGES}

# Set the default command to login shell
set_default_cmd $ctr "/bin/bash --login"

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
