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
