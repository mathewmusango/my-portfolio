#!/usr/bin/env python3
"""Draft the Unreleased section from closed issues, and check a pull request against it."""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / ".github" / "changelog.json"
CHANGELOG = ROOT / "CHANGELOG.md"
BASE = "https://github.com/mathewmusango/my-portfolio"
CLOSES = re.compile(r"\b(?:close[sd]?|fix(?:es|ed)?|resolve[sd]?)\s+#(\d+)", re.IGNORECASE)
TAG = re.compile(r"v\d+\.\d+\.\d+Z?$")


def load_config():
    return json.loads(CONFIG.read_text(encoding="utf-8"))


def label_set(labels):
    return {label.lower() for label in labels}


def section_for(labels, config):
    names = label_set(labels)
    for section in config["sections"]:
        if names & label_set(section["labels"]):
            return section["title"]
    return None


def excluded(labels, config):
    return bool(label_set(labels) & label_set(config["exclude_labels"]))


def gh(*args):
    result = subprocess.run(["gh", *args], capture_output=True, text=True, check=True)
    return result.stdout


def last_tag():
    tags = subprocess.run(
        ["git", "tag", "--sort=-creatordate"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    for tag in tags:
        if TAG.fullmatch(tag):
            return tag
    return ""


def tag_date(tag):
    out = subprocess.run(
        ["git", "log", "-1", "--format=%cI", tag],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    return out[:10]


def closed_issues():
    raw = gh(
        "issue",
        "list",
        "--state",
        "closed",
        "--limit",
        "300",
        "--json",
        "number,title,labels,stateReason,closedAt",
    )
    return json.loads(raw)


def collect(since, config):
    groups = {}
    for issue in closed_issues():
        if issue.get("stateReason") != "COMPLETED":
            continue
        if since and issue["closedAt"][:10] < since:
            continue
        labels = [label["name"] for label in issue["labels"]]
        if excluded(labels, config):
            continue
        title = section_for(labels, config) or config.get("unlabelled")
        if not title:
            continue
        groups.setdefault(title, []).append(issue)
    return groups


def draft(since):
    config = load_config()
    groups = collect(since, config)
    lines = ["## [Unreleased]", ""]
    for section in config["sections"]:
        issues = groups.get(section["title"])
        if not issues:
            continue
        lines += [f"### {section['title']}", ""]
        for issue in sorted(issues, key=lambda item: item["number"]):
            number = issue["number"]
            lines.append(f"- {issue['title']} ([#{number}]({BASE}/issues/{number}))")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def write(section):
    text = CHANGELOG.read_text(encoding="utf-8")
    head = text[: text.index("## [Unreleased]")]
    rest = text[text.index("## [Unreleased]") + len("## [Unreleased]") :]
    tail = rest[rest.index("\n## [") :] if "\n## [" in rest else "\n"
    CHANGELOG.write_text(head + section + tail, encoding="utf-8")


def check(pr):
    config = load_config()
    body = json.loads(gh("pr", "view", str(pr), "--json", "body"))["body"] or ""
    numbers = {int(number) for number in CLOSES.findall(body)}
    if len(numbers) != 1:
        print(f"the body must close exactly one issue; found {sorted(numbers) or 'none'}")
        return 1
    number = numbers.pop()
    issue = json.loads(gh("issue", "view", str(number), "--json", "labels"))
    labels = [label["name"] for label in issue["labels"]]
    if excluded(labels, config) or section_for(labels, config):
        return 0
    allowed = sorted({name for section in config["sections"] for name in section["labels"]})
    print(f"#{number} carries none of the changelog labels: {', '.join(allowed)}")
    return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--draft", action="store_true", help="print the Unreleased section")
    parser.add_argument("--write", action="store_true", help="replace Unreleased in CHANGELOG.md")
    parser.add_argument("--check", action="store_true", help="check a pull request")
    parser.add_argument("--pr", help="pull request number for --check")
    parser.add_argument("--since", help="YYYY-MM-DD lower bound (default: the last tag)")
    args = parser.parse_args(argv)

    if args.check:
        if not args.pr:
            print("--check needs --pr", file=sys.stderr)
            return 2
        return check(args.pr)

    if args.draft:
        since = args.since
        if not since:
            tag = last_tag()
            since = tag_date(tag) if tag else ""
        section = draft(since)
        if args.write:
            write(section)
            print("wrote ## [Unreleased]")
        else:
            print(section, end="")
        return 0

    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
