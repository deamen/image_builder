#!/bin/bash
set -e

# Only what ansible needs to run; general tools (git, tar, ...) come from deamen.general.install_dev_packages
# openssh-clients is needed for ansible to connect to remote hosts
# python3-libdnf5 is needed by the package module to use dnf5
ANSIBLE_PACKAGES="ansible ansible-lint openssh-clients pre-commit pipx sudo python3-libdnf5"
ANSIBLE_PIP_PACKAGES="detect-secrets molecule"
# Session D-Bus and a Secret Service (gnome-keyring) for CLIs that store credentials via libsecret
KEYRING_PACKAGES="dbus-daemon dbus-tools gnome-keyring libsecret"
# Unpinned so each build picks up the latest collection releases
# deamen.ansible pulls in deamen.general, deamen.gpg, deamen.podman and deamen.ai as dependencies;
# deamen.proton installs the Proton Drive and Proton Pass CLIs
DEAMEN_COLLECTIONS=${DEAMEN_COLLECTIONS:-deamen.ansible deamen.proton}

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-codespace}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}
# Non-root user the container runs as (AUTHORS is the image label, not a user)
CONTAINER_USER=${CONTAINER_USER:-deamen}

# Build on the locally built fedora-init image so systemd runs as PID 1 (it creates the
# per-user /run directories the keyring needs). fedora-init is not published, so
# `make container.fedora-init` must run first.
ctr=$(eval "$INIT_CONTAINER")

set_container_annotations "$ctr"

add_packages $ctr ${ANSIBLE_PACKAGES} ${KEYRING_PACKAGES}

# Add ~/.local/bin to PATH for all users
buildah run "$ctr" sh -c "echo 'export PATH=\$PATH:~/.local/bin' > /etc/profile.d/user_home_local_bin.sh"
buildah run "$ctr" chmod 0644 /etc/profile.d/user_home_local_bin.sh

# Create default user and allow passwordless sudo
buildah run "$ctr" useradd -m "${CONTAINER_USER}"
buildah run "$ctr" sh -c "echo '${CONTAINER_USER} ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/${CONTAINER_USER}"
buildah run "$ctr" chmod 0440 /etc/sudoers.d/${CONTAINER_USER}

# Keyring for the user: unlocked interactively with `keyring-unlock` after logging in. The bus and
# the keyring live in /run (tmpfs), so nothing is persisted and no password is stored anywhere.
KEYRING_UID=$(buildah run "$ctr" id -u "${CONTAINER_USER}")
buildah copy "$ctr" "$(dirname "$0")/files/keyring/keyring-unlock" /usr/local/bin/keyring-unlock
buildah copy "$ctr" "$(dirname "$0")/files/keyring/keyring-bus.sh" /etc/profile.d/keyring-bus.sh
buildah copy "$ctr" "$(dirname "$0")/files/keyring/keyring-tmpfiles.conf" /usr/lib/tmpfiles.d/keyring.conf
buildah run "$ctr" sed -i "s/UID/${KEYRING_UID}/g; s/USER/${CONTAINER_USER}/g" /usr/lib/tmpfiles.d/keyring.conf
buildah run "$ctr" chmod 0755 /usr/local/bin/keyring-unlock
buildah run "$ctr" chmod 0644 /etc/profile.d/keyring-bus.sh /usr/lib/tmpfiles.d/keyring.conf

# Install the published collections system-wide, then apply their playbooks to the container itself
buildah run "$ctr" ansible-galaxy collection install -p /usr/share/ansible/collections ${DEAMEN_COLLECTIONS}
ANSIBLE_PLAYBOOK=(ansible-playbook -i 'ansible-dev-container,' -c local -e ansible_python_interpreter=/usr/bin/python3)
# Set up the full Ansible dev environment as the user (dev packages, git prompt, aliases, ~/Prj,
# Copilot CLI, podman, Claude Code, linear-cli and its skill); system-wide tasks escalate through the passwordless sudo above
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    "${ANSIBLE_PLAYBOOK[@]}" -e install_molecule_via_pip=false deamen.ansible.configure_ansible_development_env
# Install GPG and deploy gpg-agent.conf for the user. Never import a key here: the image is public,
# so keys are imported at runtime by running the same playbook against the container
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    "${ANSIBLE_PLAYBOOK[@]}" -e config_gpg_user="${CONTAINER_USER}" -e config_gpg_import_secret_key=false \
    -e config_gpg_import_public_key=false deamen.gpg.configure_gpg_for_user
# Install himalaya into ~/.local/bin with an example config.toml. The playbook targets the implicit
# localhost; set the real account and create the GPG password file at runtime by rerunning it with -e
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    ansible-playbook -e ansible_python_interpreter=/usr/bin/python3 deamen.general.install_himalaya
# Install the Proton Drive CLI into ~/.local/bin and export PROTON_DRIVE_CREDENTIALS_STORE=unsafe_file
# from ~/.bashrc.d; sign in at runtime with "proton-drive auth login". keychain would work after
# keyring-unlock, but the keyring is reset on every container start, so unsafe_file stays the default
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    ansible-playbook -e ansible_python_interpreter=/usr/bin/python3 deamen.proton.install_proton_drive_cli
# Install the Proton Pass CLI into ~/.local/bin and export PROTON_PASS_KEY_PROVIDER=fs from ~/.bashrc.d,
# as the container cannot reach the kernel keyring; sign in at runtime with "pass-cli login"
buildah run --user "${CONTAINER_USER}" --env HOME="/home/${CONTAINER_USER}" --workingdir "/home/${CONTAINER_USER}" "$ctr" \
    ansible-playbook -e ansible_python_interpreter=/usr/bin/python3 deamen.proton.install_proton_pass_cli

# Set the working directory. The default user stays root because systemd (PID 1) must run as
# root; open shells as the user with `podman exec -u ${CONTAINER_USER} ...`
buildah config --workingdir "/home/${CONTAINER_USER}" "$ctr"

install_pipx_packages $ctr ${ANSIBLE_PIP_PACKAGES}

# Keep the fedora-init entrypoint (/sbin/init) and clear the inherited CMD so podman run does
# not pass a command to init. Start the container without a command:
#   podman run -d --name codespace <image>
# then open shells with "podman exec -it -u deamen codespace bash -l" and run keyring-unlock
buildah config --cmd '' "$ctr"

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
