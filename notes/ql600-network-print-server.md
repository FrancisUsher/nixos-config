# QL-600 network print server (generic documents)

The Brother QL-600 label printer is plugged into bubu-brain. The "type
text, print a label" web page at `bubu-brain.local/print` is done and
working (`hosts/bubu-brain/label-printer.nix` + `label_web.py`, using
`brother_ql print` directly against `/dev/usb/lp0` - no CUPS involved).

## What went wrong (community driver, now removed)

First attempt: CUPS + `pkgs.ptouch-driver` (the community foomatic/PPD
driver for Brother P-touch/QL printers), shared normally so any device
could print any document to it. This mis-paginates plain documents
against the printer's continuous-tape PPD. Confirmed via the CUPS
`texttopdf` filter run by hand, fully offline (no printer involved):

```
texttopdf 1 soong "test" 1 "PageSize=62mm" /tmp/test.txt > out.pdf
pdfinfo out.pdf   # Pages: 4, Page size: 176 x 283 pts
```

One line of text produced a 4-page PDF. Tuning `cpi`/`lpi`/margins made
no difference - page count stayed at 4 regardless, which points at
`texttopdf` assuming some fixed fallback content length (probably
US-Letter-shaped) and tiling that across the small 62mm x 100mm page
geometry, independent of the actual input. On real hardware this showed
up as several blank feed-and-cut cycles for a one-word test print -
wasted a length of tape that couldn't be rewound.

**Don't test filter/pagination changes against real tape.** Verify
offline first: run `texttopdf`/`foomatic-rip` by hand and check
`pdfinfo`/`brother_ql analyze` output, or redirect the CUPS `deviceUri`
to a `file:` backend (needs `FileDevice Yes`, off by default in NixOS's
cups-files.conf) to capture what would have been sent. Even after an
offline check looks clean, do the first real print with a throwaway/
scrap length of tape loaded, watching the first cut and ready to cancel
immediately.

## Current setup: raw queue

Swapped to a **CUPS raw queue** instead of fixing the community driver -
`hardware.printers.ensurePrinters` model is literally `"raw"`, no PPD,
no `services.printing.drivers` entry. CUPS does zero rendering and
passes bytes straight to `/dev/usb/lp0`; whatever's printing (Brother's
own official driver / P-touch Editor, running on the client machine)
has to fully raster the job itself before sending. This can't reproduce
the `texttopdf`/foomatic pagination bug above since none of that code
runs for a raw queue.

Confirmed structurally (no physical print, read-only checks only):
- `lpstat -p QL600` - idle, enabled, accepting requests
- `lpoptions -p QL600 -l` - "Unable to get PPD file: Not Found" (i.e.
  genuinely no PPD/filter chain attached)

**Not yet verified: an actual end-to-end print from a real client.**
That needs Brother's official QL-600 driver installed on a Windows or
Mac machine (see
[Brother QL-600 downloads](https://support.brother.com/g/b/downloadtop.aspx?c=us&lang=en&prod=lpql600eus)
and their
[Linux/driver install guides](https://support.brother.com/g/b/faqend.aspx?c=eu_ot&lang=en&prod=lpql700euk&faqid=faqp00100414_000)
for the general pattern), with a printer added pointing at
`ipp://bubu-brain.local:631/printers/QL600` and the driver manually
selected as Brother's QL-600 driver rather than a generic/AirPrint one
(exact steps are OS-specific - macOS's "Add Printer" lets you override
the auto-detected driver; Windows similarly lets you pick a local driver
against a network/IPP port). See also the general background on this
raw-queue-plus-vendor-driver pattern:
[Samba/CUPS raw-queue vendor-driver docs](https://www.linuxtopia.org/online_books/network_administration_guides/samba_reference_guide/29_CUPS-printing_13.html),
and this overview of the CUPS-vs-direct-USB tradeoff for label printers
generally:
[Label Printers on Linux: Brother QL and Dymo, the CUPS-or-Not Recipe](https://www.bigiron.cc/guides/label-printers-on-linux-brother-ql-and-dymo-the-cups-recipe).

Known caveat: since it's a true raw queue, CUPS does zero validation of
what gets sent - a device without Brother's driver that naively prints
to this queue will have its raw bytes shoved straight at the printer.
Untested what the QL-600 actually does with non-Brother-protocol input
(most likely just ignores it/errors, since it won't match the expected
raster init sequence, but this is unverified - be cautious the first
time some non-Brother-driver client tries to print here too).

- [ ] Verify one real end-to-end print via a client with Brother's
      driver installed, once such a client is available - start with
      scrap tape, watch the first cut.

## Reference: printer identity

- USB: `04f9:20c0`, serial `000A5G620869`, product "QL-600"
- `deviceUri = "usb://Brother/QL-600?serial=000A5G620869"`
- `/dev/usb/lp0` is group `lp`, mode `0660` - no udev rule needed

## Shelved alternative

If the raw-queue-only approach ends up too limited (e.g. wanting
Linux/non-Windows-Mac clients to print generic documents too), the
other option is swapping the community `ptouch-driver` for Brother's
own official Linux LPR + CUPS-wrapper package (deb/rpm, from the same
Brother downloads page above) so bubu-brain itself renders correctly
instead of relying on client-side drivers. Not attempted - it's a
proprietary vendor `.deb` (unlike the GPL `ptouch-driver`, not in
nixpkgs), would need packaging as a new Nix derivation, and would need
the same offline-first verification before trusting it with real tape.
