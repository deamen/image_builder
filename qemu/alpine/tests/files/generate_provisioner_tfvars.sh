#!/usr/bin/env bash
# ------------------------------------------------------------
# generate_provisioner_tfvars.sh
#
# Creates provisioner_credentials.auto.tfvars containing:
#   provisioner_password       = "<generated>"
#   provisioner_password_hash  = "<sha512 hash>"
#   qemu_tpl                   = "<path to Alpine 3.23 qcow2 image>"
#
# Requirements:
#   • pwgen   – for generating a strong password
#   • mkpasswd – from the 'whois' package (provides SHA‑512 hashing)
#   • find   – standard Unix utility (already available)
# ------------------------------------------------------------

set -euo pipefail   # Safer scripting

# ------------------------------------------------------------------
# 1️⃣  Find the Alpine 3.23 QCOW2 image
# ------------------------------------------------------------------
# The script may be executed from any directory, so we resolve the
# directory that contains the script itself (via $0) and look for
# *.qcow2 files under ../build/alpine3.23 relative to that location.
# If more than one image matches, we pick the first one (sorted
# alphabetically). Adjust the selection logic if you need a different
# image.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
image_path="$(find "${script_dir}/../../build/alpine3.23" -maxdepth 1 -type f -name '*.qcow2' | sort | head -n1)"

if [[ -z "$image_path" ]]; then
    echo "❌ No *.qcow2 image found under ../../build/alpine3.23"
    exit 1
fi

# ------------------------------------------------------------------
# 2️⃣  Generate a random password (20 characters, mixed case, numbers)
# ------------------------------------------------------------------
PASSWORD=$(pwgen --capitalize --numerals 20 1)

# ------------------------------------------------------------------
# 3️⃣  Create a SHA‑512 hash of the password.
#     mkpasswd -m sha-512 <password>
# ------------------------------------------------------------------
HASH=$(mkpasswd -m sha-512 "$PASSWORD")

# ------------------------------------------------------------------
# 4️⃣  Write everything to the tfvars file
# ------------------------------------------------------------------
TFVARS_FILE="provisioner_credentials.auto.tfvars"

cat > "$TFVARS_FILE" <<EOF
provisioner_password       = "$PASSWORD"
provisioner_password_hash  = "$HASH"
qemu_tpl                   = "file:///${image_path}"
EOF

echo "✅ $TFVARS_FILE created"
echo "   • Provisioner password: $PASSWORD"
echo "   • Image used (qemu_tpl): $image_path"
