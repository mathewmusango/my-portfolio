#!/usr/bin/env python3
"""Brace/paren balance + UTF-8 for docs/stylesheets/*.css.

Runs from the repo root (or anywhere — paths resolve from this file).
Exit 1 if any stylesheet has unbalanced braces/parens.
"""
import sys
from pathlib import Path

STYLESHEETS = Path(__file__).resolve().parent.parent / "docs" / "stylesheets"


def main() -> int:
    errors = 0
    for css in sorted(STYLESHEETS.rglob("*.css")):
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
