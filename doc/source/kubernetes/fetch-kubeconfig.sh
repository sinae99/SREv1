#!/usr/bin/env bash

# Strict mode keeps kubeconfig generation deterministic and fail-fast.
set -euo pipefail

# Work relative to the script directory.
ROOT="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="${ROOT}/../infra"

# Choose the SSH key in a sensible order: explicit env, project key, default key.
if [[ -n "${SSH_PRIVATE_KEY:-}" ]]; then
  SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY/#\~/$HOME}"
elif [[ -f "${HOME}/.ssh/SINA" ]]; then
  SSH_PRIVATE_KEY="${HOME}/.ssh/SINA"
else
  SSH_PRIVATE_KEY="${HOME}/.ssh/id_rsa"
fi

# The final kubeconfig is written next to the script.
OUT="${ROOT}/kubeconfig"

# Require the inventory first, because it proves the cluster install step happened.
if [[ ! -f "${ROOT}/inventory/mycluster/hosts.yaml" ]]; then
  echo "error: inventory not found; run ./generate-inventory.sh first" >&2
  exit 1
fi

# Pull the public address of the control plane from Terraform.
MASTER_PUBLIC="$(terraform -chdir="${INFRA_DIR}" output -json nodes | python3 -c "
import json, sys
print(json.load(sys.stdin)['vm1']['public'])
")"

# Pull the SSH user from Terraform so the connection details stay centralized.
SSH_USER="$(terraform -chdir="${INFRA_DIR}" output -raw ssh_user)"

# Build SSH flags and optionally attach the private key.
SSH_OPTS=(-o StrictHostKeyChecking=accept-new)
if [[ -f "${SSH_PRIVATE_KEY}" ]]; then
  SSH_OPTS+=(-i "${SSH_PRIVATE_KEY}")
fi

# Copy admin.conf from the control plane into a temporary local file.
echo "Fetching admin.conf from vm1 (${MASTER_PUBLIC})..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${MASTER_PUBLIC}" \
  "sudo cat /etc/kubernetes/admin.conf" > "${OUT}.tmp"

# Rewrite the API server endpoint so local kubectl can reach the cluster.
python3 - "${OUT}.tmp" "${MASTER_PUBLIC}" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])
master_public = sys.argv[2]
text = src.read_text()
text = text.replace("https://127.0.0.1:6443", f"https://{master_public}:6443")
text = text.replace("https://localhost:6443", f"https://{master_public}:6443")

# Kubespray can emit a private-IP server entry; rewrite that too if needed.
for line in text.splitlines():
    if line.strip().startswith("server:") and ":6443" in line:
        old_server = line.split("server:", 1)[1].strip()
        if master_public not in old_server:
            text = text.replace(old_server, f"https://{master_public}:6443")
        break

Path(sys.argv[1]).write_text(text)
PY

# Finalize the kubeconfig and lock down permissions.
mv "${OUT}.tmp" "${OUT}"
chmod 600 "${OUT}"

echo "Wrote ${OUT}"
echo "Run: export KUBECONFIG=${OUT} && kubectl get nodes"
