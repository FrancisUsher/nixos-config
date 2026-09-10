#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

hosts=$(nix eval --json .#nixosConfigurations --apply builtins.attrNames | tr -d '[]"' | tr ',' ' ')
local_host="$(hostname -s)"
remote_dir="nixos-config-check"

overall=0
for host in $hosts; do
  if [ "$host" = "$local_host" ]; then
    echo "== $host (local) =="
    if nixos-rebuild build --flake ".#$host"; then
      echo "[PASS] $host"
    else
      echo "[FAIL] $host"
      overall=1
    fi
    continue
  fi

  alias="pas-$host"
  echo "== $host (via $alias) =="
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$alias" true 2>/dev/null; then
    echo "[SKIP] $host unreachable"
    continue
  fi

  rsync -az --delete --exclude=.git --exclude=result ./ "$alias:$remote_dir/"
  if ssh "$alias" "nixos-rebuild build --flake ~/$remote_dir#$host"; then
    echo "[PASS] $host"
  else
    echo "[FAIL] $host"
    overall=1
  fi
done

exit $overall
