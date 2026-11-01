ARCH=${ARCH:-amd64}
BASE_IMAGE="registry.fedoraproject.org/fedora:latest"
MINIMAL_IMAGE="registry.fedoraproject.org/fedora-minimal:latest"
MINIMAL_CONTAINER="buildah from --arch $ARCH $MINIMAL_IMAGE"
BASE_CONTAINER="buildah from --arch $ARCH $BASE_IMAGE"
AUTHORS="deamen"
REGISTRY_URL="quay.io/deamen"
# Must match the IMAGE_NAME produced by buildah_fedora-init.sh, so images built
# on top of it use the locally built fedora-init rather than the stale,
# unsuffixed quay.io/deamen/fedora-init:latest. fedora-init-${ARCH} is not
# published, so build it first (`make container.fedora-dst` does this).
INIT_IMAGE="${REGISTRY_URL}/fedora-init-${ARCH}:latest"
INIT_CONTAINER="buildah from --arch $ARCH $INIT_IMAGE"
IMAGE_SOURCE="${IMAGE_SOURCE:-https://github.com/deamen/image_builder}"

set_container_annotations() {
    local ctr="$1"
    buildah config --label org.opencontainers.image.authors=${AUTHORS} "$ctr"
    buildah config --label org.opencontainers.image.title=${IMAGE_TITLE} "$ctr"
    buildah config --label org.opencontainers.image.source=${IMAGE_SOURCE} "$ctr"
}

update_and_upgrade_packages() {
    echo "Updating and upgrading packages in container $1..."
    local ctr="$1"
    buildah run "$ctr" microdnf update -y --nodocs --setopt install_weak_deps=0
    buildah run "$ctr" microdnf clean all
}

commit() {
    echo "Committing container $1 into image $2 ..."
    local ctr="$1"
    local image_name="$2"
    buildah commit "$ctr" "${image_name}"
}

commit_and_squash() {
    echo "Committing and squashing container $1 into image $2 ..."
    local ctr="$1"
    local image_name="$2"
    buildah commit --squash "$ctr" "${image_name}"
}

add_packages() {
    echo "Adding packages: $2 to container $1 ..."
    local ctr="$1"
    shift
    local packages=("$@")
    buildah run "$ctr" microdnf install -y --nodocs --setopt install_weak_deps=0 "${packages[@]}"
}

install_pipx_packages() {
    echo "Installing pip packages: $2 to container $1 ..."
    local ctr="$1"
    shift
    local packages=("$@")
    buildah run "$ctr" pipx install "${packages[@]}"
}

set_default_cmd() {
    echo "Setting default command for container $1 to $2 ..."
    local ctr="$1"
    local cmd="$2"
    buildah config --cmd "$cmd" "$ctr"
}

configure_git_prompt() {
    echo "Configuring git prompt for user $2 in container $1 ..."
    local ctr="$1"
    local user="$2"
    # Fedora's default ~/.bashrc sources everything in ~/.bashrc.d
    buildah run "$ctr" mkdir -p "/home/${user}/.bashrc.d"
    buildah copy --chown "${user}:${user}" --chmod 0644 "$ctr" "$(dirname "$0")/files/load_git-prompt.sh" "/home/${user}/.bashrc.d/load_git-prompt.sh"
    buildah run "$ctr" chown "${user}:${user}" "/home/${user}/.bashrc.d"
}
