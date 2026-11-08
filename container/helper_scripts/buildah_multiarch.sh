#!/bin/bash
# Combines the locally built <image>-amd64 and <image>-arm64 images into a multi-arch manifest and
# pushes it as <image>:latest. The per-arch images are not pushed on their own.
# Ported from deamen/cifs helper_scripts/buildah_multiarch.sh.
#
# Usage: buildah_multiarch.sh <image-name>, e.g. quay.io/deamen/fedora-init
# Log in to the registry first.

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <image-name>" >&2
    exit 1
fi

IMAGE_NAME=$1
ARCHES="amd64 arm64"

# Drop a manifest left over from an earlier run in the same storage
buildah manifest rm "${IMAGE_NAME}" 2>/dev/null || true

buildah manifest create "${IMAGE_NAME}"
for arch in ${ARCHES}; do
    buildah manifest add "${IMAGE_NAME}" "containers-storage:${IMAGE_NAME}-${arch}:latest"
done

buildah manifest push --all "${IMAGE_NAME}" "docker://${IMAGE_NAME}:latest"

buildah manifest rm "${IMAGE_NAME}"
