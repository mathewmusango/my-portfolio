#!/usr/bin/env sh
# One entry point for the local (stage-1) checks — a thin driver over the
# check-compose.yaml services. Default: run every surface whose files changed
# (diff-gated, mirroring the CI checks-*.yml skip-model). --full runs all
# surfaces unconditionally, exactly like check-compose's documented loop.
#
# Usage:
#   scripts/check_local.sh                     # all surfaces, changed files only
#   scripts/check_local.sh --full              # all surfaces, whole repo
#   scripts/check_local.sh shell python        # selected surfaces, changed only
#   scripts/check_local.sh --full shell js     # selected surfaces, whole repo
#
# Surface names match the check-compose.yaml services:
#   shell · python · yaml · yaml-syntax · js · terraform-fmt · terraform-validate
#   · terraform-lint · terraform-security     (any number, order preserved)
#
# Per-file changed-files linting (pre-commit fast path) stays in
# scripts/check_changed.sh; this script is the CI-parity gate runner.

set -eu

# shellcheck disable=SC1007  # CDPATH= cd is the intentional empty-CD cd idiom
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

# --- CLI ---------------------------------------------------------------------
MODE="diff"   # diff | full
SURFACES=""
for arg in "$@"; do
  case "$arg" in
    --full) MODE="full" ;;
    --diff) MODE="diff" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) SURFACES="$SURFACES $arg" ;;
  esac
done

ALL="shell python yaml yaml-syntax js terraform-fmt terraform-validate terraform-lint terraform-security"
if [ -z "$SURFACES" ]; then
  SURFACES="$ALL"
fi

# --- Changed files (diff mode) ----------------------------------------------
# Whole branch vs origin/main when it exists (PR-shaped), else vs HEAD;
# plus any staged/unstaged working-tree changes on top.
changed_files() {
  if git rev-parse --verify --quiet origin/main >/dev/null; then
    git diff --name-only --diff-filter=ACM origin/main...HEAD
  fi
  git diff --name-only --diff-filter=ACM
  git diff --cached --name-only --diff-filter=ACM
}

if [ "$MODE" = "diff" ]; then
  CHANGED="$(changed_files | sort -u)"
fi

# --- Surface → changed-file globs (mirror the CI checks-*.yml filters) ------
surface_touched() {
  # $1 = surface name; reads $CHANGED on stdin
  case "$1" in
    shell)              grep -qE '\.sh$|(^|/)\.githooks/' || return 1 ;;
    python)             grep -q '\.py$' || return 1 ;;
    js)                 grep -q '\.js$' || return 1 ;;
    yaml|yaml-syntax)   grep -qE '\.ya?ml$' || return 1 ;;
    terraform-*)        grep -qE '(^|/)terraform/|\.tflint\.hcl$|\.tf$' || return 1 ;;
  esac
}

# --- Run ---------------------------------------------------------------------
run_surface() {
  svc="$1"
  if [ "$MODE" = "full" ]; then
    reason="full"
  else
    if ! printf '%s\n' "$CHANGED" | surface_touched "$svc"; then
      echo "skip: $svc (no matching files changed)"
      return 0
    fi
    reason="changed"
  fi
  echo "== $svc ($reason) =="
  podman-compose -f check-compose.yaml run --rm "$svc"
}

status=0
for svc in $SURFACES; do
  if ! run_surface "$svc"; then
    echo "FAILED: $svc"
    status=1
  fi
done

if [ "$MODE" = "diff" ] && [ -z "${CHANGED:-}" ]; then
  echo "(no changed files detected — nothing to check; use --full for a whole-repo pass)"
fi
exit "$status"
