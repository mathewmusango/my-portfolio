"""MkDocs build hook — release rows always current, in two places.

Release data is generated from CHANGELOG.md — the authoritative, tag-riding
source — instead of hand-maintained tables (they drifted; 3.x was never added).
Two tokens, both newest-first:

    {{releases_rows}}     full history  → atlas/releases.md (Release Timeline)
    {{recent_releases}}   last 10 rows  → atlas/index.md   (Site Atlas landing)

Row data (versions, dates, links) is language-neutral, so every locale gets the
identical, always-current body; column *headers* stay authored per locale. Runs
per locale build via mkdocs-static-i18n (the CHANGELOG lives next to
mkdocs.yml, at the repo root).
"""

import re
from pathlib import Path

RELEASE_RE = re.compile(r"^## \[([^\]]+)\] - (\d{4}-\d{2}-\d{2})$", re.MULTILINE)

RECENT_LIMIT = 10
CHANGELOG_NAME = "CHANGELOG.md"


def _releases_from_changelog(changelog_path):
    """[(version, date)] newest first, skipping the [Unreleased] section."""
    text = Path(changelog_path).read_text(encoding="utf-8")
    return [
        (version, date)
        for version, date in RELEASE_RE.findall(text)
        if version.lower() != "unreleased"
    ]


def _row(version, date):
    tag = f"v{version}"
    base = "https://github.com/mathewmusango/my-portfolio"
    return (
        f"| [{tag}]({base}/releases/tag/{tag}) | {date} | "
        f"[Release]({base}/releases/tag/{tag}) · "
        f"[SBOM]({base}/releases/download/{tag}/sbom.cdx.json) |"
    )


def _body(releases, limit=None):
    rows = releases if limit is None else releases[:limit]
    return "\n".join(_row(version, date) for version, date in rows)


def on_page_markdown(markdown, page, config, files):
    src = page.file.src_path.replace("\\", "/")
    if not src.endswith("/atlas/index.md") and not src.endswith("/atlas/releases.md"):
        return markdown

    has_full = "{{releases_rows}}" in markdown
    has_recent = "{{recent_releases}}" in markdown
    if not has_full and not has_recent:
        return markdown

    changelog = Path(config["config_file_path"]).parent / CHANGELOG_NAME
    releases = _releases_from_changelog(changelog)
    if not releases:
        return markdown

    if has_full:
        markdown = markdown.replace("{{releases_rows}}", _body(releases))
    if has_recent:
        markdown = markdown.replace("{{recent_releases}}", _body(releases, RECENT_LIMIT))
    return markdown
