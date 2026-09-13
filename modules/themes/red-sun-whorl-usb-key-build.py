#!/usr/bin/env python3
"""Build a bootable BIOS-flash USB key from an extracted Lenovo BIOS update
package (WINUPTP.EXE, BootX64.efi, SHELLFLASH.EFI, chklogo.exe, ...),
replicating mkusbkey.bat's copy logic and dropping in a custom boot logo.
Background/history: issue #9.
"""

import argparse
import re
import shutil
import struct
import subprocess
import sys
from pathlib import Path

MAX_LOGO_BYTES = 61440  # chklogo.exe's own limit, confirmed by disassembly
LOGO_MAGIC = {
    # chklogo.exe checks the real file contents, not just the extension -
    # confirmed by disassembly. Signatures below are what it's matching.
    "bmp": (b"BM",),
    "gif": (b"GIF87a", b"GIF89a"),
    "jpg": (b"\xff\xd8\xff",),
}
STRIPPED_FILE_EXTS = {".exe", ".bat", ".txt", ".config"}
STRIPPED_DIR_NAMES = {"32bit", "64bit"}
BIOS_ID_RE = re.compile(r"^([A-Z0-9]+?)(\d{2})([A-Z])$")
DMI_BIOS_VERSION = Path("/sys/class/dmi/id/bios_version")


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


def read_current_bios_id():
    raw = DMI_BIOS_VERSION.read_text().strip()
    token = raw.split()[0]
    match = BIOS_ID_RE.match(token)
    if not match:
        sys.exit(f"Could not parse this machine's BIOS ID out of {raw!r} ({DMI_BIOS_VERSION})")
    prefix, version, suffix = match.groups()
    return raw, prefix, int(version), suffix


def find_package_bios_ids(pkg_dir):
    ids = []
    for entry in pkg_dir.iterdir():
        if entry.is_dir():
            match = BIOS_ID_RE.match(entry.name)
            if match:
                prefix, version, suffix = match.groups()
                ids.append((entry.name, prefix, int(version), suffix))
    return ids


def verify_model_compatibility(pkg_dir):
    # Lenovo's own installers (WINUPTP.EXE) get this from a live wininfo.exe
    # query and compare it against the package's declared platform IDs -
    # confirmed by disassembly. We don't have wininfo.exe here, so this
    # replicates the same check against the BIOS-ID naming convention
    # instead: a package subdirectory like N2TET93W matches this machine's
    # /sys/class/dmi/id/bios_version (e.g. N2TET89W) if the letters on
    # either side of the 2-digit revision number agree.
    current_raw, current_prefix, current_version, current_suffix = read_current_bios_id()
    candidates = find_package_bios_ids(pkg_dir)
    if not candidates:
        sys.exit(f"No BIOS-ID-named subdirectory (e.g. N2TET93W) found under {pkg_dir} "
                  "- can't verify this package is for this machine")

    matches = [c for c in candidates if (c[1], c[3]) == (current_prefix, current_suffix)]
    if not matches:
        names = ", ".join(c[0] for c in candidates)
        sys.exit(f"Current BIOS is {current_raw!r} (model {current_prefix}...{current_suffix}) "
                  f"but this package only contains: {names} - wrong package for this machine, refusing")

    name, _, version, _ = max(matches, key=lambda c: c[2])
    if version < current_version:
        sys.exit(f"Package's {name} is OLDER than the installed {current_raw!r} - "
                  "the signed capsule would refuse this at flash time anyway, refusing to build the key")
    if version == current_version:
        print(f"Note: {name} matches the installed {current_raw!r} exactly - this is a "
              "same-version reflash (allowed, but the offline-EFI path for it is still untested end to end, see issue #9)")
    else:
        print(f"Compatible: {name} is newer than the installed {current_raw!r}")


def verify_custom_logo_support(pkg_dir):
    # BIOS_LOGO.TXT's presence is exactly the signal we used during initial
    # research to confirm this model's BIOS package supports a custom
    # startup image at all - support varies per model (see issue #9).
    if not list(pkg_dir.glob("[Bb][Ii][Oo][Ss]_[Ll][Oo][Gg][Oo].[Tt][Xx][Tt]")):
        sys.exit(f"No BIOS_LOGO.TXT in {pkg_dir} - this package doesn't advertise custom "
                  "startup image support, refusing to build a key with a logo")


def sniff_logo_format(logo):
    header = logo.read_bytes()[:8]
    for fmt, signatures in LOGO_MAGIC.items():
        if any(header.startswith(sig) for sig in signatures):
            return fmt
    return None


def logo_dimensions(logo, fmt):
    data = logo.read_bytes()
    if fmt == "gif":
        return struct.unpack_from("<HH", data, 6)
    if fmt == "bmp":
        return struct.unpack_from("<ii", data, 18)
    return None  # JPEG dimension parsing isn't worth it - we never produce jpg logos


def panel_resolution():
    for modes_file in Path("/sys/class/drm").glob("card*/card*-eDP-1/modes"):
        first_mode = modes_file.read_text().splitlines()[0]
        width, height = first_mode.split("x")
        return int(width), int(height)
    return None


def validate_logo(logo):
    ext = logo.suffix.lstrip(".").lower()
    if ext not in LOGO_MAGIC:
        sys.exit(f"Logo must be .bmp, .jpg, or .gif (got: {logo})")

    size = logo.stat().st_size
    if size > MAX_LOGO_BYTES:
        sys.exit(f"Logo is {size} bytes, must be <= {MAX_LOGO_BYTES}")

    sniffed = sniff_logo_format(logo)
    if sniffed != ext:
        sys.exit(f"Logo's contents look like {sniffed or 'an unrecognized format'}, "
                  f"not {ext} as its extension claims - this violates the BIOS image "
                  "loader's file-format validation requirement")

    dims = logo_dimensions(logo, ext)
    panel = panel_resolution()
    if dims and panel:
        cap = (panel[0] * 0.4, panel[1] * 0.4)
        if dims[0] > cap[0] or dims[1] > cap[1]:
            print(f"WARNING: logo is {dims[0]}x{dims[1]}, over BIOS_LOGO.TXT's 40%-of-panel "
                  f"sizing requirement ({cap[0]:.0f}x{cap[1]:.0f} for this {panel[0]}x{panel[1]} panel). "
                  "The BIOS image loader doesn't actually enforce this at flash time, but it's untested past that size.")

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
    verify_model_compatibility(args.package_dir)
    verify_custom_logo_support(args.package_dir)
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
