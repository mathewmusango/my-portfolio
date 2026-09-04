"""MkDocs build hook — Release Timeline rows always current.

The Release Timeline page (atlas/releases.md, all locales) shows every tagged
release. Instead of hand-maintaining rows per locale (they drifted — 3.x was
never added), this hook parses CHANGELOG.md — the authoritative, tag-riding
source — and replaces a {{releases_rows}} token with the table body, newest
first:

    | [v3.2.0](…/releases/tag/v3.2.0) | 2026-09-01 | [Release](…) · [SBOM](…) |
    …

The column *headers* stay authored in each locale's page (Version/Fecha/版本 …);
the row data (versions, dates, links) is language-neutral, so every locale gets
the identical, always-current body. Runs per locale build via mkdocs-static-i18n
(the CHANGELOG lives at the repo root, above docs_dir).
"""

import re
from pathlib import Path

RELEASE_RE = re.compile(r"^## \[([^\]]+)\] - (\d{4}-\d{2}-\d{2})$", re.MULTILINE)


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


def on_page_markdown(markdown, page, config, files):
    src = page.file.src_path.replace("\\", "/")
    if not src.endswith("/atlas/releases.md") or "{{releases_rows}}" not in markdown:
        return markdown

    # CHANGELOG.md always sits next to mkdocs.yml (repo root in CI, /app in the
    # dev container) — more reliable than deriving from docs_dir.
    changelog = Path(config["config_file_path"]).parent / "CHANGELOG.md"
    releases = _releases_from_changelog(changelog)
    if not releases:
        return markdown

    body = "\n".join(_row(version, date) for version, date in releases)
    return markdown.replace("{{releases_rows}}", body)
