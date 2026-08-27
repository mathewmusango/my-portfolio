#!/usr/bin/env python3
"""One-off migration: strip the /my-portfolio prefix from stored metrics page keys.

The beacon now stores site-relative paths (/contact/, /es/metrics/analytics/ ...)
instead of GitHub-Pages-prefixed ones (/my-portfolio/contact/ ...). This rewrites
the `page` attribute of existing events so history matches the new keys.

Usage:
  python3 scripts/migrate_metrics_paths.py            # dry-run: show what would change
  python3 scripts/migrate_metrics_paths.py --apply    # perform the updates

Requires the AWS CLI and the `prod` profile (same creds as terraform). Table name
and region are hardcoded for this project. Idempotent: already-normalized keys
are never touched.
"""
import json
import re
import subprocess
import sys

TABLE = "my-portfolio-prod-metrics"
PROFILE = "prod"
REGION = "us-east-1"
PREFIX_RE = re.compile(r"^/my-portfolio(?=/|$)")


def aws(*args):
    cmd = ["aws", "--profile", PROFILE, "--region", REGION, *args]
    out = subprocess.run(cmd, capture_output=True, text=True)
    if out.returncode != 0:
        sys.exit(f"aws {' '.join(args)} failed: {out.stderr.strip()}")
    return json.loads(out.stdout)


def normalize(page):
    if not page:
        return page
    new = PREFIX_RE.sub("", page)
    return new or "/"


def scan_all():
    items, token = [], None
    while True:
        args = ["dynamodb", "scan", "--table-name", TABLE, "--output", "json"]
        if token:
            args += ["--starting-token", token]
        page = aws(*args)
        items += page.get("Items", [])
        token = page.get("NextToken")
        if not token:
            return items


def main():
    apply = "--apply" in sys.argv
    items = scan_all()
    changes = []
    for it in items:
        page = (it.get("page") or {}).get("S")
        new = normalize(page)
        if page is not None and new != page:
            changes.append((it, page, new))
    print(f"scanned {len(items)} items; {len(changes)} would change")
    for _it, old, new in changes:
        print(f"  {old!r} -> {new!r}")
    if not apply:
        print("dry-run — re-run with --apply to write")
        return
    for it, old, new in changes:
        key = {"date": it["date"], "sk": it["sk"]}
        aws(
            "dynamodb", "update-item",
            "--table-name", TABLE,
            "--key", json.dumps(key),
            "--update-expression", "SET #p = :v",
            "--expression-attribute-names", json.dumps({"#p": "page"}),
            "--expression-attribute-values", json.dumps({":v": {"S": new}}),
        )
    print(f"updated {len(changes)} items")


if __name__ == "__main__":
    main()
