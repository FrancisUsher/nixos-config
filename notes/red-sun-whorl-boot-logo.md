# Custom UEFI boot logo (red-sun-whorl)

First stage of [[red-sun-whorl-seamless-startup|the seamless themed startup
process]] - the firmware POST screen, before systemd-boot or Plymouth run.

Hardware: ThinkPad X1 Nano Gen1, MTM 20UNS02400, currently BIOS N2TET89W
v1.67, dated 2025-07-10 (source: `cat
/sys/class/dmi/id/{product_name,product_version,bios_version,bios_date}`
run on red-sun-whorl).

## Approach: `BIOS_LOGO.TXT` mechanism

Lenovo's official BIOS update package for this model - downloaded from
support.lenovo.com/us/en/downloads/ds547748, an Inno Setup installer
containing `WINUPTP.EXE` v1.71.1.49 and BIOS payload N2TET93W, extracted
with `innoextract` - includes a `BIOS_LOGO.TXT` file documenting a
built-in custom-logo feature in Lenovo's own signed update tooling, not a
firmware patch or binary edit.

**Spec** (source: `BIOS_LOGO.TXT` inside that package):

- Image ≤ 60KB.
- Format: BMP, JPG, or GIF.
- Width and height each ≤ 40% of the panel's native resolution (e.g. a
  1920x1080 panel caps at 768x432 - this X1 Nano's actual panel
  resolution not yet confirmed).
- Rename to `LOGO.BMP` / `LOGO.JPG` / `LOGO.GIF`, place next to
  `WINUPTP.EXE`, run the updater, reboot.

**No Windows required** (source: `mkusbkey.bat` inside the same
package): it creates `EFI\Boot\` (copies `BootX64.efi` there) and
`Flash\` (copies everything else there, then deletes the `.exe`/`.bat`/
`.txt`/`.config` helper files - image files are untouched) on a FAT32 USB
stick - plain `mkdir`/copy, reproducible from NixOS. Boot the laptop via
F12 -> USB HDD; Lenovo's own signed EFI flasher (`BootX64.efi`/
`SHELLFLASH.EFI`, both present in the package) does the update across a
few reboots.

This makes the operation roughly equivalent in risk to a normal BIOS
update (multi-reboot flash sequence risk) rather than a raw
firmware-patching risk.

## Open items before actually flashing

- [ ] Confirm the panel's native resolution to compute max logo
      dimensions.
- [ ] `chklogo.exe` ships in the package alongside `BIOS_LOGO.TXT`; its
      name suggests a pre-flash image validator, but its actual checks
      haven't been inspected (it's a Windows binary, not run or
      disassembled here). Since we're avoiding Windows, work out the
      real validation rules by hand from `BIOS_LOGO.TXT`'s stated spec
      rather than assume what `chklogo.exe` does.
- [ ] Malformed boot-logo images have caused real firmware-level crashes
      on other vendors' systems - LogoFAIL, CVE-2023-40238 (source:
      https://en.wikipedia.org/wiki/LogoFAIL). Validate the image
      carefully before flashing regardless of `chklogo.exe`.
- [ ] The package's BIOS payload is N2TET93W; currently installed is
      N2TET89W v1.67 (source: dmi query above, vs. the extracted
      package's `N2TET93W/` folder name) - going this route means also
      taking whatever BIOS version ships in the package, not a
      logo-only change.
- [ ] SPI backup plan: the flash chip is a Winbond 25R256JVEQ
      (W25Q256JV-compatible) in a **WSON-8** package, not SOIC-8 - a
      SOIC-8 clip gave inconsistent reads on this exact model; a WSON-8
      pogo adapter worked (source: Badcaps forum thread on this exact
      model,
      https://www.badcaps.net/forum/troubleshooting-hardware-devices-and-electronics-theory/troubleshooting-laptops-tablets-and-mobile-devices/bios-requests-only/3546312-lenovo-x1-nano-gen-1-bricked-where-to-flash-the-bios-fw,
      confirmed 2026-09-12). Same thread notes a second, redundant SPI
      chip on this board (EC firmware + backup BIOS copy).
- [ ] The actual logo artwork - out of scope for now, will be
      hand-sketched by the user later.
