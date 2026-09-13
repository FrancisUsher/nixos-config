#!/usr/bin/env python3
"""Build a bootable BIOS-flash USB key from an extracted Lenovo BIOS update
package (WINUPTP.EXE, BootX64.efi, SHELLFLASH.EFI, chklogo.exe, ...),
replicating mkusbkey.bat's copy logic and dropping in a custom boot logo.
Background/history: issue #9.
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

MAX_LOGO_BYTES = 61440  # chklogo.exe's own limit, confirmed by disassembly
VALID_LOGO_EXTS = {"bmp", "jpg", "gif"}
STRIPPED_FILE_EXTS = {".exe", ".bat", ".txt", ".config"}
STRIPPED_DIR_NAMES = {"32bit", "64bit"}


def run(cmd, **kwargs):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kwargs)


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "package_dir", type=Path,
        help="extracted Lenovo BIOS update package (has BootX64.efi, WINUPTP.EXE, ...)",
    )
    parser.add_argument(
        "device",
        help="whole-disk device node for the USB key, e.g. /dev/sdb (NOT a partition)",
    )
    parser.add_argument(
        "logo", type=Path, nargs="?",
        default=Path(__file__).parent / "red-sun-whorl-boot-logo.gif",
        help=".bmp/.jpg/.gif logo, <=60KB (default: red-sun-whorl-boot-logo.gif next to this script)",
    )
    args = parser.parse_args()
    args.package_dir = args.package_dir.resolve()
    args.logo = args.logo.resolve()
    return args


def validate_package_dir(pkg_dir):
    if not pkg_dir.is_dir():
        sys.exit(f"Not a directory: {pkg_dir}")
    if not (pkg_dir / "BootX64.efi").is_file():
        sys.exit(f"No BootX64.efi in {pkg_dir} - is this the extracted BIOS package?")


def validate_device(device):
    if not Path(device).is_block_device():
        sys.exit(f"Not a block device: {device}")


def validate_logo(logo):
    ext = logo.suffix.lstrip(".").lower()
    if ext not in VALID_LOGO_EXTS:
        sys.exit(f"Logo must be .bmp, .jpg, or .gif (got: {logo})")
    size = logo.stat().st_size
    if size > MAX_LOGO_BYTES:
        sys.exit(f"Logo is {size} bytes, must be <= {MAX_LOGO_BYTES}")
    return ext, size


def confirm_device_wipe(device):
    print("\nAbout to WIPE and repartition this device:\n")
    run(["lsblk", "-o", "NAME,SIZE,MODEL,MOUNTPOINTS", device])
    confirm = input(f"\nType the device path exactly ({device}) to confirm, anything else aborts: ")
    if confirm != device:
        sys.exit("Aborted.")


def partition_and_format(device):
    print("Wiping and creating a single FAT32 partition...")
    run(["sudo", "wipefs", "-a", device])
    # parted is a rare, one-off tool for this script - pulled in on demand
    # rather than kept in the system closure.
    run(["sudo", "nix-shell", "-p", "parted", "--run",
         f"parted -s '{device}' mklabel gpt mkpart primary fat32 1MiB 100%"])
    run(["sudo", "nix-shell", "-p", "parted", "--run", f"partprobe '{device}'"])

    part = f"{device}p1" if device[-1].isdigit() else f"{device}1"
    run(["udevadm", "settle"])
    run(["sudo", "mkfs.vfat", "-F", "32", "-n", "RSWFLASH", part])
    return part


def mount_partition(part):
    print(f"Mounting {part} via udisksctl...")
    result = run(["udisksctl", "mount", "-b", part], stdout=subprocess.PIPE, text=True)
    match = re.search(r"at (.+)\.$", result.stdout.strip())
    if not match:
        sys.exit(f"Could not determine mount point from: {result.stdout!r}")
    mount_point = Path(match.group(1))
    print(f"Mounted at {mount_point}")
    return mount_point


def copy_package_files(pkg_dir, mount_point):
    print("Copying files (mkusbkey.bat logic)...")
    (mount_point / "EFI" / "Boot").mkdir(parents=True, exist_ok=True)
    flash_dir = mount_point / "Flash"
    flash_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy(pkg_dir / "BootX64.efi", mount_point / "EFI" / "Boot" / "BootX64.efi")

    for item in pkg_dir.iterdir():
        dest = flash_dir / item.name
        if item.is_dir():
            shutil.copytree(item, dest)
        else:
            shutil.copy(item, dest)
    return flash_dir


def strip_unneeded_files(flash_dir):
    for item in list(flash_dir.iterdir()):
        if item.is_file() and item.suffix.lower() in STRIPPED_FILE_EXTS:
            item.unlink()
        elif item.is_dir() and item.name.lower() in STRIPPED_DIR_NAMES:
            shutil.rmtree(item)


def install_logo(logo, ext, size, flash_dir):
    logo_name = f"LOGO.{ext.upper()}"
    shutil.copy(logo, flash_dir / logo_name)
    print(f"Copied logo as Flash/{logo_name} ({size} bytes)")


def unmount_and_eject(part, device):
    print("Unmounting...")
    run(["udisksctl", "unmount", "-b", part])
    run(["udisksctl", "power-off", "-b", device])


def main():
    args = parse_args()

    validate_package_dir(args.package_dir)
    validate_device(args.device)
    logo_ext, logo_size = validate_logo(args.logo)

    confirm_device_wipe(args.device)
    part = partition_and_format(args.device)
    mount_point = mount_partition(part)

    flash_dir = copy_package_files(args.package_dir, mount_point)
    strip_unneeded_files(flash_dir)
    install_logo(args.logo, logo_ext, logo_size, flash_dir)

    unmount_and_eject(part, args.device)
    print("\nDone. Boot from this key (one-time boot menu, or the firmware's own boot prompt) to run the BIOS flash.")


if __name__ == "__main__":
    main()
