"""Policy rules over the workflows and the Terraform, run as a test."""

import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
WORKFLOWS = ROOT / ".github" / "workflows"
TERRAFORM = ROOT / "terraform"
PINNED = re.compile(r"^[^@\s]+@[0-9a-f]{40}$")
PUBLIC_ACL = re.compile(r'acl\s*=\s*"public-read(-write)?"')
WILDCARD = re.compile(r'"Action"\s*:\s*"\*"')


def uses_entries(node, found):
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "uses" and isinstance(value, str):
                found.append(value)
            else:
                uses_entries(value, found)
    elif isinstance(node, list):
        for item in node:
            uses_entries(item, found)
    return found


def workflow_rules(path, problems):
    data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    name = path.relative_to(ROOT)
    if "permissions" not in data:
        problems.append(f"{name}: no top-level permissions: — declare contents: read")
    for entry in uses_entries(data, []):
        if entry.startswith(("./", "docker://")):
            continue
        if not PINNED.match(entry):
            problems.append(f"{name}: uses {entry} is not pinned to a 40-character SHA")
    text = path.read_text(encoding="utf-8")
    if "write-all" in text:
        problems.append(f"{name}: write-all grants every scope")


def terraform_rules(path, problems):
    text = path.read_text(encoding="utf-8")
    name = path.relative_to(ROOT)
    for match in PUBLIC_ACL.finditer(text):
        line = text[: match.start()].count("\n") + 1
        problems.append(f"{name}:{line}: public ACL on a bucket")
    if WILDCARD.search(text) and '"Resource": "*"' in text:
        problems.append(f"{name}: an IAM statement allows every action on every resource")


def main():
    problems = []
    for path in sorted(WORKFLOWS.glob("*.yml")):
        workflow_rules(path, problems)
    for path in sorted(TERRAFORM.rglob("*.tf")):
        terraform_rules(path, problems)

    for problem in problems:
        print(problem)
    print(f"{len(problems)} policy problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
