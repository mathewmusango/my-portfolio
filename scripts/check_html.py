#!/usr/bin/env python3
"""UTF-8 + Jinja tag balance for overrides/**/*.html templates.

Checks that every {% ... %} block and {{ ... }} expression is closed —
catches truncated template edits fast. (The strict mkdocs build renders the
templates on every push; this is the file-change-time feedback.)
"""
import sys
from pathlib import Path

OVERRIDES = Path(__file__).resolve().parent.parent / "overrides"


def main() -> int:
    errors = 0
    for html in sorted(OVERRIDES.rglob("*.html")):
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
