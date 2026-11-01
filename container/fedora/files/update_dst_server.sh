#!/bin/bash
set -e

# The cluster token check lives in prepare_dst_cluster.sh: this script runs as
# an optional ("-") ExecStartPre, so a failure here is ignored by systemd.

echo "Updating DST server using SteamCMD..."
"$STEAMCMD_PATH" +runscript $DST_INSTALL_DIR/update_dst.steamcmd

echo "Updating DST server mods..."
# Use printf to send a single “Enter” at the end of the command shut down the program,
# otherwise it hangs at Shutting down and wait for user input indefinitely
printf '\n' | ${DST_INSTALL_DIR}/bin64/dontstarve_dedicated_server_nullrenderer_x64 -persistent_storage_root "${DST_USER_DATA_DIR}" -conf_dir / -ugc_directory "${DST_UGC_PATH}" -cluster Cluster_1 -only_update_server_mods -shard Master
