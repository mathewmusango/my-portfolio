#!/usr/bin/env python3
"""Brace/paren balance + UTF-8 for CSS files.

No args: scan every *.css in the repo (excluding site/ + .git). With args:
check only those files (relative to the repo root). Exit 1 if any file has
unbalanced braces/parens.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    files = [Path(a) for a in sys.argv[1:]]
    if not files:
        files = sorted(
            p
            for p in ROOT.rglob("*.css")
            if p.relative_to(ROOT).parts[0] not in ("site", ".git")
        )
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
