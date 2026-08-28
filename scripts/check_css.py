#!/usr/bin/env python3
"""Brace/paren balance + UTF-8 for CSS files.

No args: scan docs/stylesheets/**. With args: check only those files
(relative to the repo root, e.g. scripts/check_css.py docs/stylesheets/extra.css).
Exit 1 if any file has unbalanced braces/parens.
"""
import sys
from pathlib import Path

STYLESHEETS = Path(__file__).resolve().parent.parent / "docs" / "stylesheets"


def main() -> int:
    files = [Path(a) for a in sys.argv[1:]] or sorted(STYLESHEETS.rglob("*.css"))
    errors = 0
    for css in files:
        text = css.read_text(encoding="utf-8")
        if text.count("{") != text.count("}"):
            print(f"ERROR {css}: unbalanced braces")
            errors += 1
        if text.count("(") != text.count(")"):
            print(f"ERROR {css}: unbalanced parens")
            errors += 1
    print(f"{errors} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
