#!/usr/bin/env python3
"""Confirm language translations exist for the site's default-language pages.

docs_structure is "folder": each language has its own directory (docs/en/,
docs/es/, docs/zh/). For every English page under docs/en/ (recursively,
excluding the includes/ snippet directory), the Spanish (docs/es/) and
Chinese (docs/zh/) counterparts must exist — including error pages (500.md)
and nested pages (metrics/, atlas/, projects/).

Checks performed:
  - Presence:      missing es/zh page                        -> ERROR
  - Staleness:     English changed after the translation     -> ERROR
                   (git commit timestamps: en newer than es/zh
                   means an English edit was never translated)
  - Heading drift: heading-level sequence differs            -> WARNING
                   (names are localized, only structure is comparable)

Exit code is 1 if any error is found.
"""
import re
import subprocess
import sys
from pathlib import Path

LANGS = ("es", "zh")

HEADING = re.compile(r"^(#{1,6})\s+.+$")

def heading_levels(path: Path) -> list:
    """Sequence of heading levels (1-6) — a structural fingerprint that is
    language-independent (translated headings keep their level)."""
    return [
        len(m.group(1))
        for line in path.read_text(encoding="utf-8").splitlines()
        if (m := HEADING.match(line))
    ]


def last_commit_ts(path: Path) -> int:
    """Unix timestamp of the last commit touching the file (0 if never committed)."""
    try:
        out = subprocess.run(
            ["git", "log", "-1", "--format=%ct", "--", str(path)],
            capture_output=True,
            text=True,
            timeout=15,
        ).stdout.strip()
        return int(out) if out.isdigit() else 0
    except (subprocess.SubprocessError, FileNotFoundError, ValueError):
        return 0


def fmt_ts(ts: int) -> str:
    import datetime

    return datetime.datetime.fromtimestamp(ts).strftime("%Y-%m-%d") if ts else "never"


def main() -> int:
    en_dir = Path("docs/en")
    errors = []
    warnings = []

    if not en_dir.is_dir():
        print(f"ERROR docs/en/ not found (is docs_structure: folder?)")
        return 1

    for en in sorted(en_dir.rglob("*.md")):
        if "includes" in en.parts:
            continue
        rel = en.relative_to(en_dir)
        name = str(rel)
        for lang in LANGS:
            t = en_dir.parent / lang / rel
            if not t.exists():
                errors.append(f"{name}: missing translation {t}")
                continue

            # Staleness: English edited after the translation -> not translated yet.
            en_ts = last_commit_ts(en)
            t_ts = last_commit_ts(t)
            if en_ts and t_ts and en_ts > t_ts:
                errors.append(
                    f"{name} ({lang}): stale translation — English last updated "
                    f"{fmt_ts(en_ts)}, {lang} last updated {fmt_ts(t_ts)}"
                )

            # Heading structure drift (language-independent fingerprint).
            en_levels = heading_levels(en)
            t_levels = heading_levels(t)
            if en_levels != t_levels:
                warnings.append(
                    f"{name} ({lang}): heading structure differs from en "
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
