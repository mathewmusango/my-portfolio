"""MkDocs build hook — keeps the Site Metrics page facts always accurate.

The Site Metrics landing page shows "page count / last updated / delivery"
facts. Instead of hand-editing those numbers, this hook computes them at build
time and replaces {{token}} placeholders on each locale's `metrics/index.md`:

    {{pages_total}}   pages per language (from the build's own file list)
    {{last_updated}}  "Aug 2026" (latest commit touching docs/)

Works with mkdocs-static-i18n: the hook runs per locale build, and files are
filtered to the current locale by the `en|es|zh/` prefix. `last_updated` is
site-wide (same value for every locale).
"""

import datetime
import subprocess
from pathlib import Path

ES_MONTHS = ("Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")


def _locale_of(src_path):
    first = src_path.split("/", 1)[0]
    return first if first in ("en", "es", "zh") else "en"


def _fmt_month(ts, locale):
    dt = datetime.datetime.fromtimestamp(ts, tz=datetime.timezone.utc)
    if locale == "zh":
        return f"{dt.year}年{dt.month}月"
    if locale == "es":
        return f"{ES_MONTHS[dt.month - 1]} {dt.year}"
    return dt.strftime("%b %Y")


def _last_updated(repo_root, locale):
    """Latest commit touching docs/, formatted for the locale (e.g. 'Aug 2026',
    'Ago 2026', '2026年8月'). Falls back to the newest docs file mtime if git
    isn't available."""
    try:
        out = subprocess.run(
            ["git", "log", "-1", "--format=%ct", "--", "docs"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        ).stdout.strip()
        if out.isdigit():
            return _fmt_month(int(out), locale)
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        pass

    newest = 0
    for p in Path(repo_root, "docs").rglob("*.md"):
        try:
            newest = max(newest, p.stat().st_mtime)
        except OSError:
            continue
    return _fmt_month(newest, locale) if newest else "—"


def on_page_markdown(markdown, page, config, files):
    src = page.file.src_path.replace("\\", "/")
    if not src.endswith("/metrics/index.md"):
        return markdown

    locale = _locale_of(src)
    count = sum(
        1
        for f in files
        if f.src_path.replace("\\", "/").startswith(locale + "/")
    )

    replacements = {
        "pages_total": str(count),
        "last_updated": _last_updated(Path(config["docs_dir"]).parent, locale),
    }
    for key, value in replacements.items():
        markdown = markdown.replace("{{" + key + "}}", value)
    return markdown
