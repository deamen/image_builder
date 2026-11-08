#!/bin/bash
# Combines per-arch images into a multi-arch manifest and pushes it as <image-name>:latest.
# Based on deamen/cifs helper_scripts/buildah_multiarch.sh.
#
# Usage: buildah_multiarch.sh <image-name> <source>...
#   <image-name>  e.g. quay.io/deamen/fedora-init
#   <source>      a per-arch image, e.g. docker://quay.io/deamen/fedora-init@sha256:...
#                 (default: the locally built <image-name>-amd64:latest and <image-name>-arm64:latest)
# Log in to the registry first.

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <image-name> <source>..." >&2
    exit 1
fi

IMAGE_NAME=$1
shift
if [ "$#" -eq 0 ]; then
    set -- "containers-storage:${IMAGE_NAME}-amd64:latest" "containers-storage:${IMAGE_NAME}-arm64:latest"
fi

# Drop a manifest left over from an earlier run in the same storage
buildah manifest rm "${IMAGE_NAME}" 2>/dev/null || true

buildah manifest create "${IMAGE_NAME}"
for source in "$@"; do
    buildah manifest add "${IMAGE_NAME}" "${source}"
done

buildah manifest push --all "${IMAGE_NAME}" "docker://${IMAGE_NAME}:latest"

buildah manifest rm "${IMAGE_NAME}"
