# Custom UEFI boot logo (red-sun-whorl)

First stage of [[red-sun-whorl-seamless-startup|the seamless themed startup
process]] - the firmware POST screen, before systemd-boot or Plymouth run.

Hardware: ThinkPad X1 Nano Gen1, MTM 20UNS02400, Insyde H2O firmware,
currently BIOS N2TET89W v1.67 (2025-07-10).

## Approach: `BIOS_LOGO.TXT` mechanism

Confirmed present in the actual current BIOS update package for this
model (Lenovo support downloads page, package containing `WINUPTP.EXE`
version 1.71.1.49, BIOS payload N2TET93W). This is Lenovo's own
documented (if not publicly advertised) customer-facing feature, built
into their signed update tooling - not a firmware patch or binary edit.

**Spec (from `BIOS_LOGO.TXT` in the package):**

- Image ≤ 60KB.
- Format: BMP, JPG, or GIF.
- Width and height each ≤ 40% of the panel's native resolution (e.g. a
  1920x1080 panel caps at 768x432). Still need to confirm this X1 Nano's
  actual panel resolution to compute the real max.
- Rename to `LOGO.BMP` / `LOGO.JPG` / `LOGO.GIF`, place next to
  `WINUPTP.EXE`, run the updater, reboot.

**No Windows required.** The package also ships `BootX64.efi`,
`SHELLFLASH.EFI`, and `mkusbkey.bat` for a bootable-USB flash path:
`mkusbkey.bat` just creates `EFI\Boot\` (copies `BootX64.efi` there) and
`Flash\` (copies everything else there, then deletes the `.exe`/`.bat`/
`.txt`/`.config` helper files - image files are untouched) on a FAT32 USB
stick. That layout is plain `mkdir`/`cp`, fully reproducible from NixOS.
Boot the laptop via F12 -> USB HDD, and Lenovo's own signed EFI flasher
does the update, with the custom logo included, across a few reboots.

This makes the operation roughly equivalent in risk to a normal BIOS
update (multi-reboot flash sequence risk) rather than a raw
firmware-patching risk - no Boot Guard rejection concern, no UEFITool
binary surgery.

## Open items before actually flashing

- [ ] Confirm the panel's native resolution to compute max logo
      dimensions.
- [ ] `chklogo.exe` (included in the package) is the Windows-only
      pre-flash validator for the image (size/format/dimensions) - since
      we're avoiding Windows, replicate its checks by hand before
      building the USB key rather than trusting an unvalidated image
      (see LogoFAIL, CVE-2023-40238 - malformed boot-logo images have
      caused real firmware-level crashes on Insyde/AMI/Phoenix systems).
- [ ] Note the package's BIOS payload (N2TET93W) vs. currently installed
      (N2TET89W v1.67) - going this route means also taking whatever BIOS
      version ships in the package, not a logo-only change.
- [ ] Hardware SPI backup plan (agreed as a precaution regardless of
      which method was used): CH341A programmer - but confirm chip
      package before buying a clip. A Badcaps thread on this exact model
      identifies the flash chip as Winbond W25Q256JV-compatible in a
      **WSON8** package, not SOIC-8 - a SOIC-8 clip reportedly gives poor
      contact on this board; a WSON8 pogo-pin adapter worked. Same
      thread/model also has a second, redundant SPI chip (EC firmware +
      backup BIOS copy), which is good news for recoverability.
- [ ] The actual logo artwork - out of scope for now, will be
      hand-sketched by the user later.
