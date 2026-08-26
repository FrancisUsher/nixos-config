#!/usr/bin/env bash
set -euo pipefail

REPO_URL="<replace-with-your-git-remote-url>"
CONFIG_DIR="$HOME/nixos-config"
SECRETS_FILE="/etc/wifi-secrets.env"
HOSTNAME="bubu-brain"

if [ ! -d "$CONFIG_DIR" ]; then
  git clone "$REPO_URL" "$CONFIG_DIR"
fi

if [ ! -f "$SECRETS_FILE" ]; then
  echo "Missing $SECRETS_FILE. Create it manually, e.g.:"
  echo '  sudo install -m 600 /dev/stdin '"$SECRETS_FILE"' <<< '"'"'WIFI_PSK="..."'"'"''
  exit 1
fi

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
