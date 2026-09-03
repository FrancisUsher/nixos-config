#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <target-device>  (e.g. /dev/nvme0n1)" >&2
  echo "Run 'lsblk' first and pick the right device - this WILL wipe it." >&2
  exit 1
fi

DEVICE="$1"
REPO_URL="https://github.com/FrancisUsher/nixos-config.git"

echo "==> Target device: $DEVICE"
lsblk "$DEVICE"
echo
echo "THIS WILL DESTROY ALL DATA ON $DEVICE."
read -rp "Type the device path again to confirm ($DEVICE): " CONFIRM
if [ "$CONFIRM" != "$DEVICE" ]; then
  echo "Confirmation did not match, aborting." >&2
  exit 1
fi

BOOT_PART="${DEVICE}p1"
ROOT_PART="${DEVICE}p2"

echo "==> Partitioning $DEVICE"
parted "$DEVICE" -- mklabel gpt
parted "$DEVICE" -- mkpart ESP fat32 1MiB 512MiB
parted "$DEVICE" -- set 1 esp on
parted "$DEVICE" -- mkpart primary 512MiB 100%

mkfs.fat -F32 -n boot "$BOOT_PART"

cryptsetup luksFormat "$ROOT_PART"
cryptsetup luksOpen "$ROOT_PART" cryptroot
mkfs.ext4 -L nixos /dev/mapper/cryptroot

mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

echo "==> Generating hardware profile against the mounted target"
nixos-generate-config --root /mnt

echo "==> Cloning nixos-config"
git clone "$REPO_URL" /tmp/nixos-config
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nixos-config/hosts/x1nano/hardware-configuration.nix

echo "==> Installing (you'll be prompted to set the initial root password)"
nixos-install --root /mnt --flake /tmp/nixos-config#x1nano

echo
echo "==> Done. Reboot into the new system, set soong's login password (passwd),"
echo "    then follow the general steps in the root BOOTSTRAP.md, step 1 onward."
