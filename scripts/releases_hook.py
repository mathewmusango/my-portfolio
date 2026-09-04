"""MkDocs build hook — release rows always current, in two places.

Release data is generated from CHANGELOG.md — the authoritative source — instead
of hand-maintained tables (they drifted; 3.x was never added). Two tokens, both
newest-first:

    {{releases_rows}}     full history  → atlas/releases.md (Release Timeline)
    {{recent_releases}}   last 10 rows  → atlas/index.md   (Site Atlas landing)

Row data (versions, dates, links) is language-neutral, so every locale gets the
identical, always-current body; column *headers* stay authored per locale. Runs
per locale build via mkdocs-static-i18n (the CHANGELOG lives next to
mkdocs.yml, at the repo root).

Tag promotion: releases are cut by tagging the commit whose CHANGELOG still
calls the top section "[Unreleased]" — the new tag *promotes* it into the
released version. Prod builds from that tag commit, so on a v* tag build the
hook prepends the tag's version (GITHUB_REF_NAME) with the commit date, making
the just-released version appear even before the section is renamed. When the
CHANGELOG already carries the versioned section (renamed at release time), no
duplicate is added.
"""

import datetime
import os
import re
import subprocess
from pathlib import Path

RELEASE_RE = re.compile(r"^## \[([^\]]+)\] - (\d{4}-\d{2}-\d{2})$", re.MULTILINE)

RECENT_LIMIT = 10
CHANGELOG_NAME = "CHANGELOG.md"
TAG_RE = re.compile(r"^v\d+\.\d+\.\d+$")


def _git_commit_date(repo_root):
    """Date of HEAD (YYYY-MM-DD) — the release date on a tag build."""
    try:
        out = subprocess.run(
            ["git", "log", "-1", "--format=%cs"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        ).stdout.strip()
        if re.match(r"^\d{4}-\d{2}-\d{2}$", out):
            return out
    except (subprocess.SubprocessError, FileNotFoundError, OSError):
        pass
    return datetime.datetime.now(tz=datetime.timezone.utc).date().isoformat()


def _current_tag():
    """vX.Y.Z tag being built, from the CI ref name ("" locally / on main)."""
    ref = os.environ.get("GITHUB_REF_NAME", "")
    return ref if TAG_RE.match(ref) else ""


def _releases_from_changelog(changelog_path):
    """[(version, date)] newest first, skipping the [Unreleased] section."""
    text = Path(changelog_path).read_text(encoding="utf-8")
    return [
        (version, date)
        for version, date in RELEASE_RE.findall(text)
        if version.lower() != "unreleased"
    ]


def _with_tag_promotion(releases, changelog_path):
    """Prepend the tag being built when it isn't a versioned CHANGELOG section
    yet — the tag promotes the [Unreleased] content into a release."""
    tag = _current_tag()
    if not tag:
        return releases
    version = tag[1:]  # strip leading "v"
    if any(v == version for v, _ in releases):
        return releases
    promoted = list(releases)
    promoted.insert(0, (version, _git_commit_date(Path(changelog_path).parent)))
    return promoted


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
    releases = _with_tag_promotion(_releases_from_changelog(changelog), changelog)
    if not releases:
        return markdown

    if has_full:
        markdown = markdown.replace("{{releases_rows}}", _body(releases))
    if has_recent:
        markdown = markdown.replace("{{recent_releases}}", _body(releases, RECENT_LIMIT))
    return markdown
