#!/usr/bin/env bash

# Strict bash mode makes failures visible instead of silently ignored.
set -euo pipefail

# Always run from the infra directory so Terraform reads the right state.
cd "$(dirname "$0")"

# Print the known hosts and their public/private IPs for operator convenience.
list_hosts() {
  terraform output -json nodes | python3 -c '
import json, sys
for name, n in sorted(json.load(sys.stdin).items()):
    print(f"  {name}  public={n.get(\"public\") or \"-\"}  private={n.get(\"private\") or \"-\"}")
'
}

# Show the expected CLI shape and the current Terraform-derived host list.
usage() {
  echo "Usage: $0 <vm-name> [ssh options...]"
  echo
  echo "Hosts:"
  list_hosts
  exit 1
}

# The first argument is required: the VM name to connect to.
[[ $# -ge 1 ]] || usage

HOST="$1"
shift

# Resolve the target IP from Terraform output using JSON rather than text grep.
IP="$(terraform output -json nodes | python3 -c "
import json, sys
host = sys.argv[1]
n = json.load(sys.stdin)[host]
ip = n.get('public') or n.get('private')
if not ip:
    raise SystemExit(f'no ip for {host}')
print(ip)
" "$HOST")"

# Read the SSH user from Terraform so the script does not duplicate config.
USER="$(terraform output -raw ssh_user)"

# Print the final SSH command for transparency, then replace the shell process.
echo "ssh ${USER}@${IP}"
exec ssh -o StrictHostKeyChecking=accept-new "${USER}@${IP}" "$@"
