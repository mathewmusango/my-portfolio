#!/usr/bin/env python3
"""Confirm language translations exist for the site's default-language pages.

For every English page in docs/ (excluding includes/, generated files, and
the error page), the Spanish (.es.md) and Chinese (.zh.md) counterparts must
exist. Heading drift between a page and its translations is flagged as a
warning so new sections don't silently ship in only one language.

Exit code is 1 if any translation is missing.
"""
import re
import sys
from pathlib import Path

LANGS = ("es", "zh")
SKIP = {"500.md", "credentials.html"}

HEADING = re.compile(r"^(#{1,6})\s+.+$")


def heading_levels(path: Path) -> list:
    """Sequence of heading levels (1-6) — a structural fingerprint that is
    language-independent (translated headings keep their level)."""
    return [
        len(m.group(1))
        for line in path.read_text(encoding="utf-8").splitlines()
        if (m := HEADING.match(line))
    ]


def main() -> int:
    docs = Path("docs")
    errors = []
    warnings = []

    for en in sorted(docs.glob("*.md")):
        name = en.name
        if name.endswith((".es.md", ".zh.md")) or name in SKIP:
            continue
        base = name[: -len(".md")]
        for lang in LANGS:
            t = docs / f"{base}.{lang}.md"
            if not t.exists():
                errors.append(f"{name}: missing translation {t.name}")
                continue
            en_levels = heading_levels(en)
            t_levels = heading_levels(t)
            if en_levels != t_levels:
                warnings.append(
                    f"{t.name}: heading structure differs from {name} "
                    f"(levels {t_levels} vs {en_levels})"
                )

    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")

    print(f"\n{len(warnings)} warning(s), {len(errors)} error(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
