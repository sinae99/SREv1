#!/usr/bin/env bash

# Fail fast so a broken inventory or missing key does not silently continue.
set -euo pipefail

# Resolve the script directory once and reuse it.
ROOT="$(cd "$(dirname "$0")" && pwd)"

# Prefer the explicitly configured SSH key, then the project-specific SINA key,
# then a default RSA key.
if [[ -n "${SSH_PRIVATE_KEY:-}" ]]; then
  SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY/#\~/$HOME}"
elif [[ -f "${HOME}/.ssh/SINA" ]]; then
  SSH_PRIVATE_KEY="${HOME}/.ssh/SINA"
else
  SSH_PRIVATE_KEY="${HOME}/.ssh/id_rsa"
fi

# Use the Kubespray release that matches the documented challenge stack.
KUBESPRAY_IMAGE="${KUBESPRAY_IMAGE:-quay.io/kubespray/kubespray:v2.28.1}"
INVENTORY="${ROOT}/inventory/mycluster/hosts.yaml"

# Refuse to run if the inventory has not been generated yet.
if [[ ! -f "${INVENTORY}" ]]; then
  echo "error: ${INVENTORY} not found; run ./generate-inventory.sh first" >&2
  exit 1
fi

# Build the local directories and SSH known_hosts file that the container mounts.
mkdir -p "${ROOT}/kubespray_cache"
mkdir -p "${HOME}/.ssh"
touch "${HOME}/.ssh/known_hosts"

# These are the base Docker flags for running Kubespray inside a container.
DOCKER_ARGS=(
  --rm -it
  -v "${ROOT}/inventory:/kubespray/inventory"
  -v "${HOME}/.ssh/known_hosts:/root/.ssh/known_hosts"
  -v "${ROOT}/kubespray_cache:/tmp/kubespray_cache"
  -e "ANSIBLE_CONFIG=/kubespray/ansible.cfg"
)

# Extra Ansible flags keep host-key checking off inside the container.
ANSIBLE_EXTRA=(
  -e host_key_checking=False
)

# If ssh-agent is available, let Ansible use it instead of mounting the key.
if [[ -n "${SSH_AUTH_SOCK:-}" && -S "${SSH_AUTH_SOCK}" ]]; then
  echo "Using ssh-agent (${SSH_AUTH_SOCK})"
  DOCKER_ARGS+=(
    -v "${SSH_AUTH_SOCK}:/ssh-agent"
    -e "SSH_AUTH_SOCK=/ssh-agent"
  )
else
  # Fall back to the private key file when no agent is running.
  if [[ ! -f "${SSH_PRIVATE_KEY}" ]]; then
    echo "error: SSH private key not found at ${SSH_PRIVATE_KEY}" >&2
    echo "Set SSH_PRIVATE_KEY, or load a passphrase key into the agent:" >&2
    echo "  eval \"\$(ssh-agent -s)\"" >&2
    echo "  ssh-add ~/.ssh/SINA" >&2
    echo "  ./kubespray.sh" >&2
    exit 1
  fi
  echo "WARNING: no ssh-agent detected; mounting ${SSH_PRIVATE_KEY}" >&2
  echo "If this key has a passphrase, Ansible forks may fail. Prefer:" >&2
  echo "  eval \"\$(ssh-agent -s)\"" >&2
  echo "  ssh-add ${SSH_PRIVATE_KEY}" >&2
  echo "  ./kubespray.sh" >&2
  DOCKER_ARGS+=(
    -v "${SSH_PRIVATE_KEY}:/root/.ssh/id_rsa:ro"
  )
  ANSIBLE_EXTRA+=(
    -e ansible_ssh_private_key_file=/root/.ssh/id_rsa
  )
fi

# Default to the main Kubespray cluster playbook if the user did not pass args.
if [[ $# -eq 0 ]]; then
  set -- ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml --become
fi

# Launch Kubespray in Docker with the assembled mounts and arguments.
docker run "${DOCKER_ARGS[@]}" \
  "${KUBESPRAY_IMAGE}" \
  "$@" \
  "${ANSIBLE_EXTRA[@]}"
