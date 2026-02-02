#!/usr/bin/env python3
"""
Run Testinfra (pytest‑testinfra) tests against Alpine VMs

"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Dict, Any


def run_terraform_output() -> dict:
    """Execute `terraform output -json` and return the parsed JSON."""
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            capture_output=True,
            text=True,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"Failed to run `terraform output -json`: {exc.stderr.strip()}"
        ) from exc
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Terraform output is not valid JSON") from exc


def extract_ip_addresses(tf_json: dict) -> List[str]:
    """
    Find every top‑level key that ends with “_ip_addr”.
    The associated value is expected to be a dict containing a ``value`` key
    holding the actual IP string.
    """
    ips: List[str] = []
    for key, payload in tf_json.items():
        if key.endswith("_ip_addr"):
            # Payload should be a dict with a "value" entry
            if isinstance(payload, dict) and "value" in payload:
                ip = payload["value"]
                if isinstance(ip, str):
                    ips.append(ip)
                else:
                    raise RuntimeError(f"The `value` for {key} is not a string: {ip!r}")
            else:
                raise RuntimeError(f"Unexpected structure for {key}: {payload!r}")
    if not ips:
        raise RuntimeError("No keys ending with `_ip_addr` were found.")
    return ips


def read_provisioner_password(tfvars_path: Path) -> str:
    """
    Extract the provisioner password from a .tfvars file.
    Expected line (whitespace tolerant):
        provisioner_password = "xyz"
    """
    if not tfvars_path.is_file():
        raise RuntimeError(f"File not found: {tfvars_path}")
    password_pat = re.compile(
        r"""^\s*provisioner_password\s*=\s*["']([^"']+)["']\s*$"""
    )
    with tfvars_path.open() as f:
        for line in f:
            m = password_pat.match(line)
            if m:
                return m.group(1)
    raise RuntimeError(f"`provisioner_password` not found in {tfvars_path}")


def build_host_strings(
    ips: List[str], user: str, password: str, port: int = 22
) -> List[str]:
    """Create Testinfra host strings: ssh://user:pass@ip:port"""
    return [f"ssh://{user}:{password}@{ip}:{port}" for ip in ips]


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Testinfra host strings")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the generated `py.test` command without executing it",
    )
    args = parser.parse_args()
    # 1️⃣ Grab Terraform JSON output
    tf_json = run_terraform_output()
    # 2️⃣ Pull out all IP addresses (keys ending with _ip_addr)
    ip_list = extract_ip_addresses(tf_json)
    # 3️⃣ Load the password from the tfvars file
    tfvars_file = Path("provisioner_credentials.auto.tfvars")
    password = read_provisioner_password(tfvars_file)
    # 4️⃣ Build the host strings (user is fixed to ansible.svc)
    hosts = build_host_strings(ip_list, user="ansible.svc", password=password)
    # 5️⃣ Assemble the pytest‑testinfra command
    hosts_arg = ",".join(hosts)
    cmd = ["py.test", f"--hosts={hosts_arg}"]
    if args.dry_run:
        print("Generated command:")
        print(" ".join(cmd))
        sys.exit(0)
    # Run the command
    try:
        subprocess.run(cmd, check=True)
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)


if __name__ == "__main__":
    main()
