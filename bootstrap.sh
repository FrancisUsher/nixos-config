#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/FrancisUsher/nixos-config.git"
CONFIG_DIR="$HOME/nixos-config"
SECRETS_DIR="$CONFIG_DIR/secrets"
HOSTNAME="${1:-$(hostname -s)}"

if [ ! -d "$CONFIG_DIR" ]; then
  git clone "$REPO_URL" "$CONFIG_DIR"
fi

if [ ! -d "$SECRETS_DIR" ] || [ -z "$(ls -A "$SECRETS_DIR" 2>/dev/null)" ]; then
  echo "Missing secrets. Drop the required files into $SECRETS_DIR (see BOOTSTRAP.md), then re-run."
  exit 1
fi

for f in "$SECRETS_DIR"/*; do
  sudo install -m 600 "$f" "/etc/$(basename "$f")"
done

if [ -L /etc/nixos ]; then
  sudo rm /etc/nixos
elif [ -d /etc/nixos ]; then
  echo "/etc/nixos exists as a real directory. Remove/back it up manually first."
  exit 1
fi
sudo ln -s "$CONFIG_DIR" /etc/nixos

sudo nixos-rebuild switch \
  --flake "$CONFIG_DIR#$HOSTNAME" \
  --option experimental-features "nix-command flakes"

echo
echo "== Post-rebuild verification =="

CHECKS_OK=1

check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  [PASS] %s\n' "$desc"
  else
    printf '  [FAIL] %s\n' "$desc"
    CHECKS_OK=0
  fi
}

check "sshd is active" systemctl is-active --quiet sshd
check "tailscaled is active" systemctl is-active --quiet tailscaled
check "network is reachable (ping 1.1.1.1)" ping -c 1 -W 3 1.1.1.1
check "DNS resolves + HTTPS reachable (github.com)" curl -fsS --max-time 5 -o /dev/null https://github.com

echo
if [ "$CHECKS_OK" -eq 1 ]; then
  echo "All checks passed."
else
  echo "One or more checks failed above. This does NOT mean the rebuild failed -" \
    "it means double-check network/SSH access before closing this session. See" \
    "BOOTSTRAP.md step 4."
fi
