---
id: red-sun-whorl-boot-logo
aliases: []
tags: []
---
# Custom UEFI boot logo (red-sun-whorl)

First stage of [[red-sun-whorl-seamless-startup|the seamless themed startup
process]] - the firmware POST screen, before systemd-boot or Plymouth run.

Hardware: ThinkPad X1 Nano Gen1, MTM 20UNS02400, currently BIOS N2TET89W
v1.67, dated 2025-07-10 (source: `cat
/sys/class/dmi/id/{product_name,product_version,bios_version,bios_date}`
run on red-sun-whorl).

## Background

A community guide (source: https://1832jsh.github.io/thinkpad/BIOS_logo.html)
describes some ThinkPads shipping a built-in custom boot-logo option in
Lenovo's own signed update tooling, via a renamed `LOGO` file dropped
into the BIOS package's `FLASH` folder before running `winuptp.exe`. It
notes support varies per model and says to check that model's own
`BIOS_LOGO.txt`/README.

The reason we are interested in this particular approach is because unlike raw
firmware patching, there is supposedly no risk of "Boot Guard" misbehavior
if this laptop model turns out to support it. In order to verify support for
this exact model, we will proceed to inspect the relevant Lenovo BIOS Update
Utility package for our X1 Nano Gen1 model (Type 20UN/20UQ) from
support.lenovo.com/us/en/downloads/ds547748.

## Initial Firmware Update package inspection

Once we have downloaded the file, we can proceed with inspection. We got a
file from Lenovo called `n2tuj37w.exe`. Obviously this looks like a Windows
executable file but it's worth stepping down in order to discover exactly
what is going on in this file, to help us analyze.

The most basic tool to try is called `file`. It just prints the "file type",
which it determines by running a number of tests on the file:

```
> file n2tuj37w.exe
n2tuj37w.exe: PE32 executable for MS Windows 5.00 (GUI), Intel i386, 10 sections
```

Nothing too surprising here. PE32 is the standard "Portable Executable"
format Windows uses for pretty much everything it runs - .exes, DLLs,
drivers, etc. Despite the naming convention "32" this is actually just
a container format, and it doesn't actually tell us anything about the
content of the code like whether it targets 32 or 64-bit execution
platforms. This is just a genric Windows-loadable binary.

Based on a bit of digging around in the ThinkPad modding community we
can try the next step. Various online sources mention Lenovo's Windows
BIOS update packages are usually 7-zip self-extracting archives. So we
might try probing this with a 7-Zip command:

```
> 7z x n2tuj37w.exe -o./output-dir -y
```

Nothing fancy just a standard 7zip command, and not much to report in
here either. Actually it does sorta extract some stuff but everything
seems to still be in binary format. However there is one interesting
tidbit nestled in the scanned metadata that's worth diving into more:

```
  38 │ ProductVersion: 1.71.1.49                                         
  39 │ Comments: This installation was built with Inno Setup.
  40 │ CompanyName: Lenovo Group Limited                                        
  41 │ FileDescription: For Lenovo Updates Catalog
```

On line 39 we can see the name of the installer packaging software is
called "Inno Setup". So in order to unpack it, we should target that
installer platform. There is a well-known tool called `innoextract`
for doing just this:

```
❯ rm -rf ./output-dir; innoextract -e -m -d output-dir/ n2tuj37w.exe 
Extracting "version 1.71-1.49 (N2TET93W-N2THT73W)" - setup data version 5.5.7 (unicode)
 - "code$GetExtractPath$/WINUPTP.EXE" - overwritten
 - "code$GetExtractPath$/806A1.PAT"
 - "code$GetExtractPath$/806C0.PAT"
 - "code$GetExtractPath$/806C1.PAT"
 - "code$GetExtractPath$/806D1.PAT"
 - "code$GetExtractPath$/BCP.evs"
 - "code$GetExtractPath$/BIOS_LOGO.TXT"
 - "code$GetExtractPath$/BootX64.efi"
 - "code$GetExtractPath$/chklogo.exe"
 - "code$GetExtractPath$/chklogo.exe.config"
 - "code$GetExtractPath$/DeleteFolder.xml"
 - "code$GetExtractPath$/DeleteTasks.xml"
 - "code$GetExtractPath$/Instruction - Update model number.txt"
 - "code$GetExtractPath$/Instruction JP - BIOS flash USB memory key.txt"
 - "code$GetExtractPath$/Instruction US - BIOS flash USB memory key.txt"
 - "code$GetExtractPath$/mkusbkey.bat"
 - "code$GetExtractPath$/pwdchk.exe"
 - "code$GetExtractPath$/pwdchk64.exe"
 - "code$GetExtractPath$/SHELLFLASH.EFI"
 - "code$GetExtractPath$/WinFlash32.exe"
 - "code$GetExtractPath$/WinFlash32s.exe"
 - "code$GetExtractPath$/WinFlash64.exe"
 - "code$GetExtractPath$/WinFlash64s.exe"
 - "code$GetExtractPath$/wininfo.exe"
 - "code$GetExtractPath$/wininfo64.exe"
 - "code$GetExtractPath$/WINUPTP.EXE"
 - "code$GetExtractPath$/WINUPTP64.EXE"
 - "code$GetExtractPath$/32bit/tpnflhlp.sys"
 - "code$GetExtractPath$/64bit/tpnflhlp.sys"
 - "code$GetExtractPath$/N2TET93W/$0AN2T00.FL1"
 - "code$GetExtractPath$/N2TET93W/$0AN2T00.FL2"
Done.
```

Now that's more like it! There are a number of interesting files in
there but among the gems is what we were looking for: `BIOS_LOGO.TXT`.
This file contains exactly the instructions for how to replace your
"Lenovo" startup logo with a custom image. It's actually really
simple - I won't copy it all here but there are a few constraints:

- Max of 60KB;
- BMP, JPEG, or GIF format;
- Max of 40% of the built-in LCD panel resolution (per dimension).

Unfortunately there's one other catch. We have to run another Windows
`.exe` file called `WINUPTP.EXE` to compile the image into the BIOS
update system - but we're on Linux! So we have a couple options.
We could either emulate windows to run this executable, or figure
out what it does and write a script to do the same thing.

Before we investigate other approaches, let's just dive deeper here
to see what `WINUPTP.EXE` actually does. We will need a couple utils
from the package `binutils`, called `strings` and `objdump`.




-----
ABOVE HERE IS HUMAN WRITTEN CONTENT
BELOW HERE IS AI WRITTEN CONTENT
-----

It's an Inno Setup installer
(`ProductName: ThinkPad BIOS Update Utility -Package 1.5.11.5`), so a
generic archive tool won't unpack the real payload - `innoextract` is
required. Extracting it confirmed BIOS payload version N2TET93W and
`WINUPTP.EXE` v1.71.1.49, and turned up both `BIOS_LOGO.TXT` and a
`chklogo.exe` validator inside, confirming the mechanism applies to this
exact model rather than just ThinkPads in general.

```
$ innoextract -e -m -d extracted/ n2tuj37w.exe
Extracting "version 1.71-1.49 (N2TET93W-N2THT73W)" - setup data version 5.5.7 (unicode)
 - "code$GetExtractPath$/WINUPTP.EXE" - overwritten
 - "code$GetExtractPath$/BIOS_LOGO.TXT"
 - "code$GetExtractPath$/chklogo.exe"
 - "code$GetExtractPath$/N2TET93W/$0AN2T00.FL1"
 - "code$GetExtractPath$/N2TET93W/$0AN2T00.FL2"
 ... (30 files total, listed and explained below)
Done.

$ cat 'extracted/code$GetExtractPath$/BIOS_LOGO.TXT'
(full contents quoted in Spec below)
```

All 30 extracted files (source: `find` over the `innoextract` output directory),
and their role in the package as best determined - some are confirmed by direct
inspection, some are inferred from filename/context and flagged as such:

- `BIOS_LOGO.TXT` - the custom-logo spec, covered above; the source for what
  several other files below actually do.
- `WINUPTP.EXE` / `WINUPTP64.EXE` - `BIOS_LOGO.TXT` says to run this (after
  placing a `LOGO` file next to it) as the last step to apply the update.
  Beyond that instruction, its full scope (e.g. whether it also updates EC
  firmware) isn't confirmed - we haven't run or inspected the binary itself.
- `WinFlash32.exe` / `WinFlash32s.exe` / `WinFlash64.exe` / `WinFlash64s.exe` -
  an older/parallel Windows flashing GUI bundled alongside `WINUPTP.EXE`;
  exact difference between the two tool generations (or what the `s` suffix
  means) not confirmed.
- `Instruction - Update model number.txt` - documents an unrelated feature of
  `WINUPTP.EXE` (`-m` flag) for rewriting the machine-type/model string in
  NVRAM.
- `mkusbkey.bat` - the batch script that builds a bootable USB flash key from
  this package's contents: creates `EFI\Boot\` (copying `BootX64.efi` there)
  and `Flash\` (copying the rest of the package there, minus the Windows-only
  helper files).
- `Instruction US - BIOS flash USB memory key.txt` / `Instruction JP - ...` -
  the English and Japanese instructions for using the USB key `mkusbkey.bat`
  builds.
- `BootX64.efi` - the EFI bootloader stub `mkusbkey.bat` copies to
  `EFI\Boot\` on the USB key; this is what the firmware's F12 boot menu
  actually launches when booting from the stick.
- `SHELLFLASH.EFI` - inferred to be the actual EFI Shell-based flashing
  program that `BootX64.efi` hands off to, reading the `Flash\` folder and
  writing the firmware outside any OS; not independently confirmed by
  inspection beyond its name and place in `mkusbkey.bat`'s file layout.
- `N2TET93W/$0AN2T00.FL1` and `$0AN2T00.FL2` - the actual firmware image
  payloads written to the SPI chip(s); `.FL1`/`.FL2` plausibly correspond to
  the primary and secondary chip noted in the SPI backup item below, but
  that correspondence isn't confirmed.
- `chklogo.exe` / `chklogo.exe.config` - the Windows logo validator and its
  .NET runtime config (the `.config` file implies `chklogo.exe` is a .NET
  binary); presumed to check a candidate logo against `BIOS_LOGO.TXT`'s
  rules, per the open item below, not run or disassembled here.
- `pwdchk.exe` / `pwdchk64.exe` - inferred to check for a supervisor/BIOS
  password before allowing a flash to proceed; not confirmed by inspection.
- `wininfo.exe` / `wininfo64.exe` - inferred to query current BIOS/EC
  version and system info to gate compatibility before flashing; not
  confirmed by inspection.
- `32bit/tpnflhlp.sys` / `64bit/tpnflhlp.sys` - Windows kernel-mode drivers
  (architecture-specific) that plausibly grant the Windows flashing tools
  direct access to the SPI/EC interface; not confirmed by inspection.
- `806A1.PAT`, `806C0.PAT`, `806C1.PAT`, `806D1.PAT` - `.PAT` patch files;
  likely EC or platform microcode/patch blobs applied during the update.
  Exact contents/purpose not inspected.
- `BCP.evs` - inferred to be a Lenovo BIOS Configuration Program settings
  export (default UEFI setup values for fleet imaging); not confirmed.
- `DeleteFolder.xml` / `DeleteTasks.xml` - inferred to be cleanup manifests
  used by Lenovo's update orchestration (e.g. Vantage/System Update) to
  remove temp files/scheduled tasks after the update; not confirmed.

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
