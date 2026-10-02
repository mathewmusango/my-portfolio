#!/usr/bin/env python3
"""Execute composite actions' `run:` bodies the way GitHub's runner does.

A composite action's body runs only inside a job, so a body that fails under
`bash -e -o pipefail` — an empty match in a pipeline, a missing variable, a
guard that aborts before it prints — passes `actionlint`, `shellcheck` and
every required check, and surfaces only when that job finally runs.

Each body is read straight from its `action.yml`, executed under the runner's
shell flags against a fixture, and asserted. Hermetic: no network, no site
build, no AWS.

Exit code is 1 if any case fails.
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]
ACTIONS = REPO / ".github" / "actions"
INPUT_EXPR = re.compile(r"\$\{\{\s*inputs\.([A-Za-z0-9_-]+)\s*\}\}")

SITE_URL = "https://target.example/"
METRICS_ENDPOINT = "https://metrics.example"
HOST_SITE = "site-url.invalid"
HOST_METRICS = "metrics-endpoint.invalid"
PLACEHOLDER_SITE = f"https://{HOST_SITE}/"


def run_composite(name, overrides, cwd):
    """Run every bash `run:` step of a composite, in order, and return
    (step name, CompletedProcess) pairs."""
    path = ACTIONS / name / "action.yml"
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    inputs = {
        key: str((spec or {}).get("default", ""))
        for key, spec in (doc.get("inputs") or {}).items()
    }
    inputs.update(overrides)

    results = []
    for step in doc["runs"]["steps"]:
        if "run" not in step:
            continue
        if step.get("shell") != "bash":
            raise SystemExit(f"{name}: step {step.get('name')!r} is not a bash step")
        if "if" in step:
            raise SystemExit(
                f"{name}: step {step.get('name')!r} has an 'if:', which this "
                "harness does not model — extend it before adding the case"
            )
        env = dict(os.environ)
        for key, value in (step.get("env") or {}).items():
            raw = value if isinstance(value, str) else str(value)
            env[key] = INPUT_EXPR.sub(lambda m: inputs.get(m.group(1), ""), raw)
        proc = subprocess.run(
            ["bash", "-e", "-o", "pipefail", "-c", step["run"]],
            cwd=cwd,
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )
        results.append((step.get("name", "<unnamed>"), proc))
    return results


def write(root, rel, text):
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def read(root, rel):
    return (root / rel).read_text(encoding="utf-8", errors="replace")


def containing(root, needle):
    return [
        str(p.relative_to(root))
        for p in sorted(root.rglob("*"))
        if p.is_file() and needle in p.read_text(encoding="utf-8", errors="replace")
    ]


def first_failure(results):
    for name, proc in results:
        if proc.returncode != 0:
            return name, proc
    return None


def indent(text):
    return "".join(f"        | {line}\n" for line in text.splitlines())


def case_slash_only():
    """The shape the build produces: `site_url` is baked with its trailing
    slash, so the bare-form pass has nothing left to match once the slash
    pass has run."""
    def build(root):
        write(root, "site/index.html",
              '<link rel="canonical" href="https://site-url.invalid/about/">\n'
              '<meta name="metrics-endpoint" content="https://metrics-endpoint.invalid">\n')
        write(root, "site/sitemap.xml", "<loc>https://site-url.invalid/</loc>\n")
        write(root, "site/assets/vendor.min.js", 'var bundle="foo.invalid";\n')

    def check(root, results):
        problems = []
        if first_failure(results):
            problems.append("the body did not complete")
        survivors = containing(root, HOST_SITE) + containing(root, HOST_METRICS)
        if survivors:
            problems.append(f"a placeholder host survived: {survivors}")
        if SITE_URL not in read(root, "site/index.html"):
            problems.append("the real site_url did not reach index.html")
        if METRICS_ENDPOINT not in read(root, "site/index.html"):
            problems.append("the real metrics endpoint did not reach index.html")
        if "foo.invalid" not in read(root, "site/assets/vendor.min.js"):
            problems.append("a non-placeholder .invalid string was rewritten")
        return problems

    return "site_url appears only in its trailing-slash form", build, check


def case_bare_standalone():
    """A slash-less occurrence must still be substituted, not left to trip
    the guard."""
    def build(root):
        write(root, "site/index.html",
              '<link rel="canonical" href="https://site-url.invalid/about/">\n')
        write(root, "site/robots.txt", "Sitemap: https://site-url.invalid\n")

    def check(root, results):
        problems = []
        if first_failure(results):
            problems.append("the body did not complete")
        survivors = containing(root, HOST_SITE) + containing(root, HOST_METRICS)
        if survivors:
            problems.append(f"a placeholder host survived: {survivors}")
        if SITE_URL.removesuffix("/") not in read(root, "site/robots.txt"):
            problems.append("the slash-less occurrence was not substituted")
        return problems

    return "a slash-less site_url occurrence is substituted", build, check


def case_metrics_absent():
    """No metrics endpoint in the artifact: the metrics pass must be a no-op,
    not a fault."""
    def build(root):
        write(root, "site/index.html",
              '<link rel="canonical" href="https://site-url.invalid/about/">\n')

    def check(root, results):
        problems = []
        if first_failure(results):
            problems.append("the body did not complete with no metrics endpoint")
        if containing(root, HOST_SITE):
            problems.append("a placeholder host survived")
        return problems

    return "an absent metrics endpoint is a no-op", build, check


def case_placeholder_missing():
    """A body whose input never carried the placeholder must fail loudly, not
    silently deploy a broken domain."""
    def build(root):
        write(root, "site/index.html", "<html><body>no placeholder here</body></html>\n")

    def check(root, results):
        problems = []
        failure = first_failure(results)
        if not failure:
            problems.append("the body succeeded on an artifact with no placeholder")
            return problems
        output = failure[1].stdout + failure[1].stderr
        if f"no '{PLACEHOLDER_SITE}'" not in output:
            problems.append("the failure did not name the missing placeholder")
        if "::error::" not in output:
            problems.append("the failure did not raise ::error::")
        return problems

    return "a missing placeholder fails loudly", build, check


CASES = [
    case_slash_only(),
    case_bare_standalone(),
    case_metrics_absent(),
    case_placeholder_missing(),
]


def main() -> int:
    failures = 0
    for description, build, check in CASES:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build(root)
            results = run_composite(
                "inject-env-urls",
                {"site_url": SITE_URL, "metrics_endpoint": METRICS_ENDPOINT},
                root,
            )
            problems = check(root, results)

        if not problems:
            print(f"ok    {description}")
            continue
        failures += 1
        print(f"FAIL  {description}")
        for problem in problems:
            print(f"        {problem}")
        for name, proc in results:
            if proc.returncode != 0:
                print(f"        step {name!r} exited {proc.returncode}")
                print(indent(proc.stdout), end="")
                print(indent(proc.stderr), end="")

    print(f"\n{len(CASES) - failures} passed, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
