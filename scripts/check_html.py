#!/usr/bin/env python3
"""UTF-8 + Jinja tag balance for HTML/Jinja templates.

No args: scan every *.html in the repo (excluding site/ + .git). With args:
check only those files (relative to the repo root). Catches truncated
template edits fast. (The strict mkdocs build renders templates on every
push; this is file-change-time feedback.)
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    files = [Path(a) for a in sys.argv[1:]]
    if not files:
        files = sorted(
            p
            for p in ROOT.rglob("*.html")
            if p.relative_to(ROOT).parts[0] not in ("site", ".git")
        )
    errors = 0
    for html in files:
        text = html.read_text(encoding="utf-8")
        if text.count("{%") != text.count("%}"):
            print(f"ERROR {html}: unbalanced Jinja {{% %}} tags")
            errors += 1
        if text.count("{{") != text.count("}}"):
            print(f"ERROR {html}: unbalanced Jinja {{ }} expressions")
            errors += 1
    print(f"{errors} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
