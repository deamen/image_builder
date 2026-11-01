#!/bin/bash
set -e

STEAMCMD_PACKAGES="glibc.i686 tar gzip glibc-langpack-en"
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
STEAMCMD_INSTALL_DIR="/usr/local/bin"
STEAMCMD_PATH="/usr/local/bin/steamcmd.sh"
# libcurl-gnutls is in patrickl/wine-tkg
DST_PACKAGES="libcurl-gnutls"
DST_USER_DATA_DIR="/opt/klei/dst_user_data"
DST_INSTALL_DIR="/opt/klei/dst"
DST_MODS_PATH="$DST_USER_DATA_DIR/mods"
DST_UGC_PATH="$DST_MODS_PATH/ugc"
# Pristine copy of the shipped mods directory, used to seed an empty volume
DST_MODS_DEFAULT_PATH="/opt/klei/dst_mods_default"

source "$(dirname "$0")/fedora_vars.sh"
IMAGE_TITLE=${IMAGE_TITLE:-fedora-dst}
IMAGE_NAME=${IMAGE_NAME:-${REGISTRY_URL}/${IMAGE_TITLE}-${ARCH}}

# The DST dedicated server and SteamCMD are x86 only, fail early rather than
# after pulling several GB of game files
if [ "$ARCH" != "amd64" ]; then
    echo "Error: ${IMAGE_TITLE} only supports ARCH=amd64 (got ${ARCH})" >&2
    exit 1
fi

# Build on fedora-init rather than fedora-minimal: the server is run by systemd
# units, and fedora-init provides systemd as PID 1 (ENTRYPOINT /sbin/init) plus
# the SIGRTMIN+3 stop signal. fedora-minimal has neither systemd nor dnf.
ctr=$(eval "$INIT_CONTAINER")

set_container_annotations "$ctr"

# dnf5 (with dnf5-plugins) is already in fedora-init, the dnf4 "copr" command
# used previously does not exist on Fedora 41+
buildah run $ctr dnf copr enable -y patrickl/wine-tkg
add_packages $ctr ${STEAMCMD_PACKAGES}
add_packages $ctr ${DST_PACKAGES}

# Install and update SteamCMD
# Single quotes around the URL so it isn't terminating the outer double quotes
buildah run $ctr sh -c "cd $STEAMCMD_INSTALL_DIR && \
    curl -sqL '$STEAMCMD_URL' | tar zxvf -"
# SteamCMD's first run updates itself and commonly exits non-zero (e.g. 7)
# even though it succeeded, which would abort the build under set -e. A really
# broken SteamCMD still fails the build at the install_dst runscript below.
buildah run $ctr "$STEAMCMD_PATH" +quit || true

buildah run $ctr mkdir -p $DST_INSTALL_DIR
buildah run $ctr mkdir -p $DST_USER_DATA_DIR

# Deploy DST SteamCMD script
buildah run $ctr sh -c "cat > $DST_INSTALL_DIR/install_dst.steamcmd << 'EOF'
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir ${DST_INSTALL_DIR}
login anonymous
app_update 343050 validate
quit
EOF"
buildah run $ctr sh -c "cat > $DST_INSTALL_DIR/update_dst.steamcmd << 'EOF'
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
force_install_dir ${DST_INSTALL_DIR}
login anonymous
app_update 343050
quit
EOF"
buildah run $ctr "$STEAMCMD_PATH" +runscript $DST_INSTALL_DIR/install_dst.steamcmd
# Keep a pristine copy of the mods directory: a bind-mounted volume is not
# populated from the image (only named volumes are), so prepare_dst_cluster.sh
# seeds it from here at service start
buildah run $ctr cp -a $DST_INSTALL_DIR/mods $DST_MODS_DEFAULT_PATH
# Move the mods directory to the persistent storage and create a symlink to it in the installation directory, so that mods can be persisted across container restarts and updates
buildah run $ctr mv $DST_INSTALL_DIR/mods $DST_USER_DATA_DIR
buildah run $ctr ln -s $DST_USER_DATA_DIR/mods $DST_INSTALL_DIR/mods
buildah run $ctr mkdir -p $DST_UGC_PATH

# Configure container runtime environment variables
buildah config --env STEAMCMD_PATH=${STEAMCMD_PATH} $ctr
buildah config --env DST_INSTALL_DIR=${DST_INSTALL_DIR} $ctr
buildah config --env DST_USER_DATA_DIR=${DST_USER_DATA_DIR} $ctr
buildah config --env DST_MODS_PATH=${DST_MODS_PATH} $ctr
buildah config --env DST_UGC_PATH=${DST_UGC_PATH} $ctr
buildah config --env DST_MODS_DEFAULT_PATH=${DST_MODS_DEFAULT_PATH} $ctr

# Copy the DST helper scripts used by the systemd units
buildah copy --chmod=0755 $ctr "$(dirname "$0")/files/prepare_dst_cluster.sh" /usr/local/bin/prepare_dst_cluster.sh
buildah copy --chmod=0755 $ctr "$(dirname "$0")/files/update_dst_server.sh" /usr/local/bin/update_dst_server.sh

# No CMD/ENTRYPOINT here: fedora-init already starts /sbin/init as PID 1

buildah config --volume $DST_USER_DATA_DIR $ctr
buildah config --port "10998-10999/udp" $ctr
buildah config --port "27017-27018/udp" $ctr

# Copy systemd service files
buildah copy $ctr "$(dirname "$0")/files/dst_master.service" /etc/systemd/system/dst_master.service
buildah copy $ctr "$(dirname "$0")/files/dst_caves.service" /etc/systemd/system/dst_caves.service

# Enable the systemd services
buildah run $ctr systemctl enable dst_master.service
buildah run $ctr systemctl enable dst_caves.service

commit_and_squash $ctr ${IMAGE_NAME}

# Remove the container after committing the image
buildah rm $ctr
