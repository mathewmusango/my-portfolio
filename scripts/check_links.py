#!/usr/bin/env python3
"""Post-build link checker for the MkDocs site.

Crawls the built site/ directory and reports:
  - broken internal links (missing target files)
  - missing fragment anchors (id="..."/name="...")
  - absolute-path links (/...) that would break on GitHub Pages project sites

Exit code is 1 if any broken link is found.
"""
import posixpath
import re
import sys
from pathlib import Path

SCHEME = re.compile(r"^[a-z][a-z0-9+.-]*:", re.IGNORECASE)
ATTR = re.compile(r'(?:href|src)=["\']([^"\']+)["\']', re.IGNORECASE)
ID = re.compile(r'\bid=["\']([^"\']+)["\']')
NAME = re.compile(r'\bname=["\']([^"\']+)["\']')


def main() -> int:
    site = Path(sys.argv[1] if len(sys.argv) > 1 else "site").resolve()
    if not site.is_dir():
        print(f"error: site dir not found: {site}")
        return 2

    broken = []
    warnings = []

    for page in sorted(site.rglob("*.html")):
        rel_page = page.relative_to(site).as_posix()
        text = page.read_text(encoding="utf-8", errors="replace")

        for raw in ATTR.findall(text):
            link = raw.split("#", 1)
            target = link[0].split("?", 1)[0]
            frag = link[1] if len(link) > 1 else ""

            if not target and not frag:
                continue
            if SCHEME.match(raw) or raw.startswith("//"):
                continue  # external link

            if target.startswith("/"):
                warnings.append(
                    f"{rel_page}: absolute link (breaks on GitHub Pages project site): {raw}"
                )
                continue

            # Resolve the target relative to the current page.
            resolved = (
                posixpath.normpath(posixpath.join(posixpath.dirname(rel_page), target))
                if target
                else rel_page
            )
            if resolved == ".":
                resolved = "index.html"

            # Directory targets resolve to their index.html.
            candidate = site / resolved
            if candidate.is_dir():
                resolved = posixpath.join(resolved, "index.html")

            target_file = site / resolved
            if not target_file.is_file():
                broken.append(f"{rel_page}: missing target: {raw} -> {resolved}")
                continue

            if frag:
                ttext = target_file.read_text(encoding="utf-8", errors="replace")
                tids = set(ID.findall(ttext)) | set(NAME.findall(ttext))
                if frag not in tids:
                    broken.append(f"{rel_page}: missing anchor #{frag} in {resolved}")

    for w in warnings:
        print(f"WARN  {w}")
    for b in broken:
        print(f"ERROR {b}")

    print(f"\n{len(warnings)} warning(s), {len(broken)} broken link(s)")
    return 1 if broken else 0


if __name__ == "__main__":
    sys.exit(main())
