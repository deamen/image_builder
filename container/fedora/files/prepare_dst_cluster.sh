#!/bin/bash
set -e

# Run as a mandatory (non "-") ExecStartPre of both shards, so a missing token
# stops the unit instead of letting the server start and crash-loop.

# The persistent storage path is generated like this:
# ${DST_USER_DATA_DIR}/${conf_dir}/${cluster}/
# Shard configuration files are in ${DST_USER_DATA_DIR}/${conf_dir}/${cluster}/Master and ${DST_USER_DATA_DIR}/${conf_dir}/${cluster}/Caves
# Check ${DST_USER_DATA_DIR}/Cluster_1/cluster_token.txt exists and is not empty, if not, exit with error message
if [ ! -s "${DST_USER_DATA_DIR}/Cluster_1/cluster_token.txt" ]; then
    echo "Error: ${DST_USER_DATA_DIR}/Cluster_1/cluster_token.txt does not exist or is empty. Please make sure to create the cluster token file with the correct token value before running the DST server."
    exit 1
fi

# A bind-mounted volume starts empty (only named volumes are populated from
# the image), which leaves the ${DST_INSTALL_DIR}/mods symlink dangling.
# Seed any missing files from the pristine copy, without overwriting the
# user's own modsettings.lua / dedicated_server_mods_setup.lua.
mkdir -p "${DST_UGC_PATH}"
cp -an "${DST_MODS_DEFAULT_PATH}/." "${DST_MODS_PATH}/"
