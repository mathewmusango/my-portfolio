"""Load the built site in headless Firefox and assert the resume viewer renders.

Usage: python3 scripts/check_browser.py SITE_DIR [--timeout SECONDS]

Serves a copy of SITE_DIR with a probe injected into the viewer pages, drives
headless Firefox at each page, and exits non-zero when a page fails to render or
reports a script error.
"""

from __future__ import annotations

import argparse
import functools
import http.server
import json
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
from pathlib import Path
from typing import ClassVar

PAGES = (
    "resume/index.html",
    "es/resume/index.html",
    "zh/resume/index.html",
    "assets/pdf-viewer.html",
)

DECISIVE = frozenset({"rendered", "failed"})

PROBE = """<script>
(function(){
 var errs=[];
 function state(tag){
  var el=document.getElementById('pdf-pages');
  return {tag:tag,
   pages: el?el.querySelectorAll('.pdf-page').length:-1,
   canvases: document.querySelectorAll('#pdf-pages canvas').length,
   text: (el&&el.textContent||'').trim().slice(0,120),
   errs: errs.slice(0,5)};
 }
 function send(tag){
  try{ fetch('/__report?'+encodeURIComponent(JSON.stringify(state(tag))),{keepalive:true,mode:'no-cors'}); }catch(e){}
 }
 window.addEventListener('error', function(e){
  if(e && e.target && e.target.tagName) errs.push('resource '+(e.target.tagName||'')+' '+(e.target.src||e.target.href||''));
  else errs.push('error '+(e.message||''));
 }, true);
 window.addEventListener('unhandledrejection', function(e){
  errs.push('rejection '+((e.reason&&e.reason.message)||e.reason));
 });
 try{
  new MutationObserver(function(){
   var el=document.getElementById('pdf-pages');
   if(!el) return;
   if(el.querySelectorAll('.pdf-page').length>0) send('rendered');
   else if(/could not be loaded|unavailable/i.test(el.textContent||'')) send('failed');
  }).observe(document.documentElement,{childList:true,subtree:true});
 }catch(e){}
 setTimeout(function(){ send('t1'); }, 1000);
 setTimeout(function(){ send('t5'); }, 5000);
})();
</script>"""


class _Handler(http.server.SimpleHTTPRequestHandler):
    reports: ClassVar[list] = []

    def do_GET(self):
        if self.path.startswith("/__report"):
            query = urllib.parse.urlparse(self.path).query
            try:
                _Handler.reports.append(json.loads(urllib.parse.unquote(query)))
            except ValueError:
                _Handler.reports.append({"tag": "unparsable", "raw": query[:200]})
            self.send_response(204)
            self.end_headers()
            return
        super().do_GET()

    def log_message(self, *args):
        pass


def _decisive() -> bool:
    return any(report.get("tag") in DECISIVE for report in _Handler.reports)


def _free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def _firefox() -> str:
    for name in ("firefox", "firefox-esr"):
        found = shutil.which(name)
        if found:
            return found
    raise SystemExit("headless browser not found: firefox is required on PATH")


def _drive(binary: str, url: str, timeout: float, settle: float = 1.5) -> bool:
    profile = tempfile.mkdtemp(prefix="check-browser-profile-")
    Path(profile, "user.js").write_text(
        'user_pref("browser.shell.checkDefaultBrowser", false);\n', encoding="utf8"
    )
    process = subprocess.Popen(
        [binary, "--headless", "--no-remote", "--profile", profile, url],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            if _decisive():
                time.sleep(settle)
                return True
            if process.poll() is not None:
                return _decisive()
            time.sleep(0.25)
        return False
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
        shutil.rmtree(profile, ignore_errors=True)


def _script_errors(report: dict) -> list:
    return [e for e in report.get("errs") or [] if not str(e).startswith("resource ")]


def _evaluate(reports: list) -> tuple[bool, str]:
    decisive = [r for r in reports if r.get("tag") in DECISIVE]
    if not decisive:
        last = reports[-1] if reports else None
        detail = "" if last is None else " (last state: " + json.dumps(last)[:160] + ")"
        return False, "the page never reported a render or a viewer error" + detail
    report = decisive[-1]
    if report.get("tag") == "failed":
        return False, "the viewer showed an error: " + repr((report.get("text") or "").strip())
    pages = report.get("pages") or 0
    canvases = report.get("canvases") or 0
    if pages <= 0 or canvases <= 0:
        return False, f"render reported without content (pages={pages}, canvases={canvases})"
    errors = _script_errors(report)
    if errors:
        return False, "rendered, but the page reported script errors: " + "; ".join(map(str, errors))
    return True, f"{pages} page(s), {canvases} canvas(es)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("site_dir", type=Path, help="built site directory to serve")
    parser.add_argument("--timeout", type=float, default=45.0, help="seconds per page")
    args = parser.parse_args()

    if not args.site_dir.is_dir():
        raise SystemExit(f"site directory not found: {args.site_dir}")
    missing = [page for page in PAGES if not (args.site_dir / page).is_file()]
    if missing:
        raise SystemExit("missing built pages: " + ", ".join(missing))

    binary = _firefox()
    mirror = Path(tempfile.mkdtemp(prefix="check-browser-site-"))
    failures = []
    server = None
    try:
        shutil.copytree(args.site_dir, mirror, dirs_exist_ok=True)
        for page in PAGES:
            target = mirror / page
            html = target.read_text(encoding="utf8")
            if "</body>" not in html:
                raise SystemExit(f"no </body> in {page}")
            target.write_text(html.replace("</body>", PROBE + "</body>"), encoding="utf8")

        handler = functools.partial(_Handler, directory=str(mirror))
        server = http.server.ThreadingHTTPServer(("127.0.0.1", _free_port()), handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        base = f"http://127.0.0.1:{server.server_address[1]}/"

        for page in PAGES:
            url = base + page.removesuffix("index.html")
            _Handler.reports.clear()
            reported = _drive(binary, url, args.timeout)
            passed, detail = _evaluate(list(_Handler.reports))
            if not reported and passed:
                passed, detail = False, "no report from the page before the timeout"
            print(f"{'PASS' if passed else 'FAIL'}  {page}  {detail}")
            if not passed:
                failures.append(page)
    finally:
        if server is not None:
            server.shutdown()
        shutil.rmtree(mirror, ignore_errors=True)

    if failures:
        print("\nbrowser smoke check failed: " + ", ".join(failures))
        return 1
    print("\nbrowser smoke check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
