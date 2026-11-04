#!/bin/bash
set -e

# Only what ansible needs to run; general tools (git, tar, ...) come from deamen.general.install_dev_packages
# openssh-clients is needed for ansible to connect to remote hosts
# python3-libdnf5 is needed by the package module to use dnf5
ANSIBLE_PACKAGES="ansible ansible-lint openssh-clients pre-commit pipx sudo python3-libdnf5"
ANSIBLE_PIP_PACKAGES="detect-secrets molecule"
# Unpinned so each build picks up the latest collection releases
# deamen.ansible pulls in deamen.general, deamen.gpg, deamen.podman and deamen.ai as dependencies
DEAMEN_COLLECTIONS=${DEAMEN_COLLECTIONS:-deamen.ansible}

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-ansible}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}
# Non-root user the container runs as (AUTHORS is the image label, not a user)
CONTAINER_USER=${CONTAINER_USER:-deamen}

# Create a new container from the fedora-minimal image with specified architecture
ctr=$(eval "$MINIMAL_CONTAINER")

set_container_annotations "$ctr"

add_packages $ctr ${ANSIBLE_PACKAGES}

# Add ~/.local/bin to PATH for all users
buildah run "$ctr" sh -c "echo 'export PATH=\$PATH:~/.local/bin' > /etc/profile.d/user_home_local_bin.sh"
buildah run "$ctr" chmod 0644 /etc/profile.d/user_home_local_bin.sh

# Create default user and allow passwordless sudo
buildah run "$ctr" useradd -m "${CONTAINER_USER}"
buildah run "$ctr" sh -c "echo '${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CONTAINER_USER}"
buildah run "$ctr" chmod 0440 /etc/sudoers.d/${CONTAINER_USER}

# Install the published collections system-wide, then apply their playbooks to the container itself
buildah run "$ctr" ansible-galaxy collection install -p /usr/share/ansible/collections ${DEAMEN_COLLECTIONS}
ANSIBLE_PLAYBOOK=(ansible-playbook -i 'ansible-dev-container,' -c local -e ansible_python_interpreter=/usr/bin/python3)
# Set up the full Ansible dev environment as the user (dev packages, git prompt, aliases, ~/Prj,
# Copilot CLI, podman, linear-cli); system-wide tasks escalate through the passwordless sudo above
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    "${ANSIBLE_PLAYBOOK[@]}" -e install_molecule_via_pip=false deamen.ansible.configure_ansible_development_env
# Install GPG and deploy gpg-agent.conf for the user. Never import a key here: the image is public,
# so keys are imported at runtime by running the same playbook against the container
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    "${ANSIBLE_PLAYBOOK[@]}" -e config_gpg_user="${CONTAINER_USER}" -e config_gpg_import_secret_key=false \
    -e config_gpg_import_public_key=false deamen.gpg.configure_gpg_for_user

# Set the default user and working directory for the container
buildah config --user "${CONTAINER_USER}" "$ctr"
buildah config --workingdir "/home/${CONTAINER_USER}" "$ctr"

install_pipx_packages $ctr ${ANSIBLE_PIP_PACKAGES}

# Set the default command to login shell. To keep it running in the background,
# start with -dit (bash exits without a tty/stdin) and --init (bash as PID 1
# ignores SIGTERM, so podman stop would wait for the timeout):
#   podman run -dit --init --name ansible <image>
# then open shells with "podman exec -it ansible bash -l". Avoid "podman attach":
# exiting that shell stops the container (detach with Ctrl-p Ctrl-q instead).
set_default_cmd $ctr "/bin/bash --login"

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
