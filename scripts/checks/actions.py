#!/usr/bin/env python3
"""Check the repo's actions, and the workflow wiring that uses them.

Both checks exist because these faults only surface in the job that owns them:

  - a composite action's `run:` body is executed the way the runner does, so a
    body that fails under `bash -e -o pipefail` — an empty match in a pipeline,
    a missing variable, a guard that aborts before it prints — cannot hide
    behind `actionlint` and `shellcheck`;
  - a workflow job that uses a local action (`uses: ./…`) must check out first,
    because the runner loads a local action out of the workspace.

Hermetic: no network, no site build, no AWS. Exit code is 1 if any check fails.
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
WORKFLOWS = REPO / ".github" / "workflows"
EXPR = re.compile(r"\$\{\{\s*(.+?)\s*\}\}")
INPUT_REF = re.compile(r"^inputs\.([A-Za-z0-9_-]+)$")
OUTPUT_REF = re.compile(r"^steps\.([A-Za-z0-9_-]+)\.outputs\.([A-Za-z0-9_-]+)$")
IF_REF = re.compile(
    r"^steps\.([A-Za-z0-9_-]+)\.outputs\.([A-Za-z0-9_-]+)\s*(==|!=)\s*'([^']*)'$"
)

SITE_URL = "https://target.example/"
METRICS_ENDPOINT = "https://metrics.example"
HOST_SITE = "site-url.invalid"
HOST_METRICS = "metrics-endpoint.invalid"
PLACEHOLDER_SITE = f"https://{HOST_SITE}/"


def resolve_expr(expr, inputs, outputs):
    """Resolve inputs.<name> and steps.<id>.outputs.<name>; refuse anything
    else so a new construct fails loudly rather than resolving to empty."""
    ref = INPUT_REF.match(expr)
    if ref:
        return inputs.get(ref.group(1), "")
    ref = OUTPUT_REF.match(expr)
    if ref:
        return outputs.get(ref.group(1), {}).get(ref.group(2), "")
    raise SystemExit(f"unmodelled expression: {expr!r} — extend the harness")


def substitute(text, inputs, outputs):
    return EXPR.sub(lambda m: resolve_expr(m.group(1), inputs, outputs), text)


def evaluate_if(condition, inputs, outputs):
    """The `if:` form the actions use: steps.<id>.outputs.<name> ==/!= 'value'."""
    match = IF_REF.match(substitute(condition.strip(), inputs, outputs))
    if not match:
        raise SystemExit(
            f"unmodelled if: {condition!r} — extend the harness before adding the case"
        )
    actual = outputs.get(match.group(1), {}).get(match.group(2), "")
    equal = actual == match.group(4)
    return equal if match.group(3) == "==" else not equal


def read_github_output(path):
    """The simple `key=value` form the actions write to $GITHUB_OUTPUT."""
    values = {}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, _, value = line.partition("=")
            values[key.strip()] = value
    return values


def run_composite(name, overrides, cwd, env_overrides=None, path_prepend=None):
    """Run every bash `run:` step of a composite, in order, the way the runner
    does: `if:` is evaluated against outputs earlier steps wrote, `${{ }}` is
    substituted from inputs and those outputs, and $GITHUB_OUTPUT is captured so
    a later step sees them. Returns ([(step name, CompletedProcess)], outputs)."""
    path = ACTIONS / name / "action.yml"
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    inputs = {
        key: str((spec or {}).get("default", ""))
        for key, spec in (doc.get("inputs") or {}).items()
    }
    inputs.update(overrides)

    outputs = {}
    results = []
    for step in doc["runs"]["steps"]:
        if "run" not in step:
            continue
        if step.get("shell") != "bash":
            raise SystemExit(f"{name}: step {step.get('name')!r} is not a bash step")
        if "if" in step and not evaluate_if(str(step["if"]), inputs, outputs):
            continue
        env = dict(os.environ)
        if env_overrides:
            env.update(env_overrides)
        if path_prepend:
            env["PATH"] = os.pathsep.join([path_prepend, env.get("PATH", "")])
        for key, value in (step.get("env") or {}).items():
            env[key] = substitute(str(value), inputs, outputs)
        with tempfile.NamedTemporaryFile("w+", encoding="utf-8") as gh_output:
            env["GITHUB_OUTPUT"] = gh_output.name
            proc = subprocess.run(
                ["bash", "-e", "-o", "pipefail", "-c",
                 substitute(step["run"], inputs, outputs)],
                cwd=cwd,
                env=env,
                capture_output=True,
                text=True,
                timeout=60,
                check=False,
            )
            step_outputs = read_github_output(gh_output.name)
        if step.get("id"):
            outputs[step["id"]] = step_outputs
        results.append((step.get("name", "<unnamed>"), proc))
    return results, outputs


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


AWS_STUB = '''#!/usr/bin/env bash
# Test double for the aws CLI: records each call, answers the subcommands used.
set -euo pipefail
echo "$*" >> "$STUB_LOG"
case "${1:-} ${2:-}" in
  "cloudfront list-distributions")
    echo "${STUB_DISTRIBUTION_ID:-EDFDVBD6EXAMPLE}"
    ;;
  "s3 ls")
    if [ "${STUB_S3_LS_FOUND:-false}" = "true" ]; then
      echo "2026-10-05 00:00:00          0 ${3:-}"
    fi
    ;;
  "s3 sync"|"s3api put-object"|"cloudfront create-invalidation")
    ;;
  *)
    echo "stub aws: unexpected subcommand: $*" >&2
    exit 2
    ;;
esac
'''


AWS_INPUTS = {
    "project": "portfolio",
    "env": "staging",
    "run_id": "1234",
    "deploy_role_arn": "arn:aws:iam::123456789012:role/deploy",
    "invalidate_role_arn": "arn:aws:iam::123456789012:role/invalidate",
    "aws_region": "us-east-1",
    "site_url": "https://target.example/",
    "metrics_endpoint": "https://metrics.example",
}


def write_aws_stub(root):
    """Write the stub `aws`, returning the dir to prepend to PATH."""
    stub_dir = root / ".stub"
    stub_dir.mkdir(parents=True, exist_ok=True)
    stub = stub_dir / "aws"
    stub.write_text(AWS_STUB, encoding="utf-8")
    stub.chmod(0o755)
    return str(stub_dir)


def aws_log(root):
    path = root / ".stub" / "aws.log"
    return path.read_text(encoding="utf-8") if path.exists() else ""


def case_aws_release():
    """hash_skip=false: a release always syncs and invalidates, and plants no
    marker, because the hash is set only on the hash_skip path."""
    def build(root):
        write(root, "site/index.html", "<html>release</html>\n")

    def check(root, results, outputs):
        problems = []
        if first_failure(results):
            problems.append("the action did not complete")
        if outputs.get("check", {}).get("changed") != "true":
            problems.append("a release did not set changed=true")
        log = aws_log(root)
        if "s3 sync site/" not in log:
            problems.append("the site was not synced")
        if "--delete" not in log:
            problems.append("the sync did not pass --delete")
        if "--exclude .deploy-hash/*" not in log:
            problems.append("the sync did not exclude the marker prefix")
        if "put-object" in log:
            problems.append("a release planted a deploy marker")
        if "create-invalidation" not in log:
            problems.append("the distribution was not invalidated")
        return problems

    return (
        "a release (hash_skip=false) syncs, invalidates, and plants no marker",
        build,
        None,
        None,
        check,
    )


def case_aws_first_deploy():
    """hash_skip=true with no marker: deploy, and plant the marker next time."""
    def build(root):
        write(root, "site/index.html", "<html>first</html>\n")

    def check(root, results, outputs):
        problems = []
        if first_failure(results):
            problems.append("the action did not complete")
        summary = outputs.get("check", {})
        if summary.get("changed") != "true":
            problems.append("a first deploy did not set changed=true")
        digest = summary.get("hash", "")
        if not digest:
            problems.append("a first deploy did not record the content hash")
        log = aws_log(root)
        if "s3 ls s3://portfolio-staging-site/.deploy-hash/" not in log:
            problems.append("the marker was not existence-checked")
        if "s3 sync site/" not in log:
            problems.append("the site was not synced")
        if "s3api put-object" not in log or f".deploy-hash/{digest}" not in log:
            problems.append("the marker was not planted for the next run")
        if "create-invalidation" not in log:
            problems.append("the distribution was not invalidated")
        return problems

    return (
        "a first hash_skip deploy syncs and plants the marker",
        build,
        {"hash_skip": "true"},
        {"STUB_S3_LS_FOUND": "false"},
        check,
    )


def case_aws_unchanged():
    """hash_skip=true with the marker present: nothing is synced or invalidated."""
    def build(root):
        write(root, "site/index.html", "<html>unchanged</html>\n")

    def check(root, results, outputs):
        problems = []
        if first_failure(results):
            problems.append("the action did not complete")
        if outputs.get("check", {}).get("changed") != "false":
            problems.append("an unchanged artifact did not set changed=false")
        log = aws_log(root)
        if "s3 ls" not in log:
            problems.append("the marker existence was not checked")
        for forbidden in ("s3 sync", "put-object", "create-invalidation"):
            if forbidden in log:
                problems.append(f"an unchanged artifact still ran {forbidden!r}")
        return problems

    return (
        "an unchanged hash_skip artifact deploys nothing",
        build,
        {"hash_skip": "true"},
        {"STUB_S3_LS_FOUND": "true"},
        check,
    )


DEPLOY_CASES = [
    case_aws_release(),
    case_aws_first_deploy(),
    case_aws_unchanged(),
]


def wiring_problems():
    """Local `uses: ./…` steps, in jobs that never check out. The runner loads
    a local action from the workspace, so a checkout has to precede it."""
    problems = []
    for path in sorted(WORKFLOWS.glob("*.yml")):
        doc = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        for job_id, job in (doc.get("jobs") or {}).items():
            if not isinstance(job, dict) or "steps" not in job:
                continue
            checked_out = False
            for step in job["steps"]:
                uses = str(step.get("uses") or "")
                if uses.startswith("actions/checkout"):
                    checked_out = True
                elif uses.startswith("./") and not checked_out:
                    problems.append(
                        f"{path.name}: job '{job_id}' uses {uses} "
                        "before any actions/checkout"
                    )
    return problems


STATIC_CHECKS = [
    ("a local action is preceded by actions/checkout", wiring_problems),
]


CASES = [
    case_slash_only(),
    case_bare_standalone(),
    case_metrics_absent(),
    case_placeholder_missing(),
]


def report(description, problems, results):
    """Print one case's result; returns 1 when it failed."""
    if not problems:
        print(f"ok    {description}")
        return 0
    print(f"FAIL  {description}")
    for problem in problems:
        print(f"        {problem}")
    for name, proc in results:
        if proc.returncode != 0:
            print(f"        step {name!r} exited {proc.returncode}")
            print(indent(proc.stdout), end="")
            print(indent(proc.stderr), end="")
    return 1


def main() -> int:
    failures = 0
    total = 0

    for description, probe in STATIC_CHECKS:
        total += 1
        failures += report(description, probe(), [])

    for description, build, check in CASES:
        total += 1
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build(root)
            results, _ = run_composite(
                "inject-env-urls",
                {"site_url": SITE_URL, "metrics_endpoint": METRICS_ENDPOINT},
                root,
            )
            problems = check(root, results)
        failures += report(description, problems, results)

    for description, build, input_overrides, env_overrides, check in DEPLOY_CASES:
        total += 1
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            build(root)
            stub_dir = write_aws_stub(root)
            inputs = dict(AWS_INPUTS)
            inputs.update(input_overrides or {})
            env = dict(env_overrides or {})
            env["STUB_LOG"] = str(root / ".stub" / "aws.log")
            results, outputs = run_composite(
                "aws-s3",
                inputs,
                root,
                env_overrides=env,
                path_prepend=stub_dir,
            )
            problems = check(root, results, outputs)
        failures += report(description, problems, results)

    print(f"\n{total - failures} passed, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
