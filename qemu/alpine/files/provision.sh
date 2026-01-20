#!/bin/ash
set -euxo pipefail

# Setup proxy if exists
[ -f /etc/profile.d/proxy.sh ] && source /etc/profile.d/proxy.sh

###
# upgrade all packages.
# --available: This flag instructs apk to upgrade packages only if newer versions are available.
# Without this flag, apk might attempt to reinstall packages even if they are already at the latest version.
###
apk upgrade --update-cache --available

###
# Install essential packages
###
essential_packages="
  vim
  logrotate
  python3
  py3-pip
  doas
"
apk add $essential_packages

# Install and enable QEMU Guest Agent from edge/community repo
apk add qemu-guest-agent --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
rc-update add qemu-guest-agent

###
# Install and setup Cloud Init
# e2fsprogs-extra is required by Cloud Init for creating/resizing filesystems.
# See https://git.alpinelinux.org/aports/tree/community/cloud-init/README.Alpine.
###
apk add cloud-init e2fsprogs-extra mount py3-pyserial py3-netifaces --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
setup-cloud-init
