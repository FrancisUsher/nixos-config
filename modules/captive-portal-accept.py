"""Headless captive-portal login for public wifi.

Detects a captive portal via plain HTTP (no cert errors), tries to submit
its accept/agree form directly, and falls back to a real headless browser
click if that heuristic doesn't clear it.

Usage:
  captive-portal-accept              detect + accept, remember network on success
  captive-portal-accept --no-learn   accept but don't remember the network
  captive-portal-accept --check      just report status, take no action
  captive-portal-accept --forget     stop auto-accepting on the current network
"""
import argparse
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from urllib.parse import urlencode, urljoin

CHECK_URL = "http://connectivitycheck.gstatic.com/generate_204"
UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36"
TIMEOUT = 6
ACCEPT_RE = re.compile(r"accept|agree|connect|continue|get.?online|proceed|join|terms|tos", re.I)

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local" / "state"))) / "captive-portal"
KNOWN_FILE = STATE_DIR / "known-networks"

FORM_RE = re.compile(r"<form\b([^>]*)>(.*?)</form>", re.I | re.S)
INPUT_RE = re.compile(r"<input\b([^>]*)/?>", re.I | re.S)
BUTTON_RE = re.compile(r"<button\b([^>]*)>(.*?)</button>", re.I | re.S)
ATTR_RE = re.compile(r'(\w[\w-]*)\s*=\s*"([^"]*)"|(\w[\w-]*)\s*=\s*\'([^\']*)\'|(\w[\w-]*)\s*=\s*([^\s>]+)')


def log(msg):
    print(f"[captive-portal] {msg}", file=sys.stderr)


def fetch(url, data=None, method="GET"):
    req = urllib.request.Request(url, data=data, method=method, headers={"User-Agent": UA})
    return urllib.request.urlopen(req, timeout=TIMEOUT)


def check_connectivity():
    """Return (online, portal_url_or_None)."""
    try:
        resp = fetch(CHECK_URL)
        if resp.status == 204:
            return True, None
        return False, resp.geturl()
    except urllib.error.HTTPError as e:
        return (e.code == 204), (e.geturl() or CHECK_URL)
    except Exception:
        return False, None


def parse_attrs(s):
    out = {}
    for m in ATTR_RE.finditer(s):
        for i in (0, 2, 4):
            if m.group(i + 1) is not None:
                out[m.group(i + 1).lower()] = m.group(i + 2)
                break
    return out


def extract_forms(html_text):
    forms = []
    for attrs_str, body in FORM_RE.findall(html_text):
        attrs = parse_attrs(attrs_str)
        fields = {}
        for inp_attrs in INPUT_RE.findall(body):
            a = parse_attrs(inp_attrs)
            name = a.get("name")
            if not name:
                continue
            itype = a.get("type", "text").lower()
            if itype == "submit":
                continue
            if itype in ("checkbox", "radio"):
                checked = "checked" in inp_attrs.lower()
                looks_like_agree = ACCEPT_RE.search(name + " " + a.get("value", ""))
                if checked or looks_like_agree:
                    fields[name] = a.get("value", "on")
            else:
                fields[name] = a.get("value", "")
        submit_text = ""
        for btn_attrs, btn_text in BUTTON_RE.findall(body):
            a = parse_attrs(btn_attrs)
            if a.get("name"):
                fields.setdefault(a["name"], a.get("value", ""))
            submit_text += " " + btn_text
        forms.append({
            "action": attrs.get("action", ""),
            "method": attrs.get("method", "get").lower(),
            "fields": fields,
            "text": body + submit_text,
        })
    return forms


def try_heuristic(portal_url):
    log(f"fetching portal page: {portal_url}")
    try:
        resp = fetch(portal_url)
        body = resp.read().decode("utf-8", "replace")
        page_url = resp.geturl()
    except Exception as e:
        log(f"could not fetch portal page: {e}")
        return False

    forms = extract_forms(body)
    if not forms:
        log("no <form> found on portal page")
        return False

    forms.sort(key=lambda f: bool(ACCEPT_RE.search(f["text"])), reverse=True)
    form = forms[0]
    action = urljoin(page_url, form["action"] or page_url)
    log(f"submitting form to {action} ({form['method']}) with fields {list(form['fields'])}")

    try:
        if form["method"] == "post":
            fetch(action, data=urlencode(form["fields"]).encode(), method="POST")
        else:
            sep = "&" if "?" in action else "?"
            fetch(action + sep + urlencode(form["fields"]))
    except Exception as e:
        log(f"form submit failed: {e}")
        return False

    time.sleep(2)
    online, _ = check_connectivity()
    return online


def try_browser(portal_url):
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        log("playwright not installed, skipping browser fallback "
            "(enable services.captivePortalAccept.enableBrowserFallback)")
        return False

    log("falling back to headless browser")
    clicked = False
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(user_agent=UA)
        page.goto(portal_url, wait_until="networkidle", timeout=15000)
        for el in page.locator("button, input[type=submit], a").all():
            try:
                text = (el.inner_text() or "") + " " + (el.get_attribute("value") or "")
            except Exception:
                continue
            if ACCEPT_RE.search(text):
                el.click(timeout=3000)
                clicked = True
                break
        if not clicked:
            log("no accept-looking button found in browser")
        page.wait_for_timeout(2500)
        browser.close()

    if not clicked:
        return False
    time.sleep(1)
    online, _ = check_connectivity()
    return online


def active_wifi_uuid():
    try:
        out = subprocess.run(
            ["nmcli", "-t", "-f", "TYPE,UUID", "connection", "show", "--active"],
            capture_output=True, text=True, timeout=5, check=True,
        ).stdout
    except Exception as e:
        log(f"could not read active connection via nmcli: {e}")
        return None
    for line in out.splitlines():
        if line.startswith("802-11-wireless:"):
            return line.split(":", 1)[1]
    return None


def record_known_network():
    uuid = active_wifi_uuid()
    if not uuid:
        return
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    known = set(KNOWN_FILE.read_text().split()) if KNOWN_FILE.exists() else set()
    if uuid not in known:
        with KNOWN_FILE.open("a") as f:
            f.write(uuid + "\n")
        log(f"remembered this network ({uuid}) for auto-accept next time")


def forget_network():
    uuid = active_wifi_uuid()
    if not uuid or not KNOWN_FILE.exists():
        log("nothing to forget")
        return
    known = set(KNOWN_FILE.read_text().split())
    if uuid in known:
        known.discard(uuid)
        KNOWN_FILE.write_text("\n".join(sorted(known)) + ("\n" if known else ""))
        log(f"forgot this network ({uuid}) — will require manual accept again")
    else:
        log("this network wasn't in the auto-accept list")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--check", action="store_true", help="only report connectivity status, take no action")
    ap.add_argument("--no-learn", action="store_true", help="don't remember this network for auto-accept")
    ap.add_argument("--forget", action="store_true", help="remove current network from the auto-accept list")
    args = ap.parse_args()

    if args.forget:
        forget_network()
        sys.exit(0)

    online, portal_url = check_connectivity()
    if online:
        log("already online, no portal detected")
        sys.exit(0)

    if args.check:
        print(f"captive portal at: {portal_url or 'unknown'}")
        sys.exit(1)

    if not portal_url:
        log("offline and no portal URL found (not connected at all?)")
        sys.exit(2)

    ok = try_heuristic(portal_url) or try_browser(portal_url)

    if ok:
        log("portal accepted, now online")
        if not args.no_learn:
            record_known_network()
        sys.exit(0)

    log("could not clear the portal automatically — open a browser this time")
    sys.exit(1)


if __name__ == "__main__":
    main()
