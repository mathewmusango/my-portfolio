#!/usr/bin/env sh
set -eu

# shellcheck disable=SC1007  # CDPATH= cd is the intentional empty-CD cd idiom
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$ROOT"

if [ -t 1 ]; then
  ESC=$(printf '\033')
  BOLD="${ESC}[1m"; GREEN="${ESC}[32m"; YELLOW="${ESC}[33m"; RED="${ESC}[31m"; NC="${ESC}[0m"
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; NC=""
fi

ALL="shell python yaml yaml-syntax js terraform-fmt terraform-validate terraform-lint terraform-security"
MODE="diff"
VERBOSE=0
SURFACES=""

usage() {
  printf 'usage: %s [--full] [--diff] [--verbose] [surface ...]\n' "$0"
  printf 'surfaces: %s\n' "$ALL"
  printf 'docs: scripts/checks/README.md\n'
}

for arg in "$@"; do
  case "$arg" in
    --full) MODE="full" ;;
    --diff) MODE="diff" ;;
    --verbose|-v) VERBOSE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) SURFACES="$SURFACES $arg" ;;
  esac
done

if [ -z "$SURFACES" ]; then
  SURFACES="$ALL"
fi

changed_files() {
  if git rev-parse --verify --quiet origin/main >/dev/null; then
    git diff --name-only --diff-filter=ACM origin/main...HEAD
  fi
  git diff --name-only --diff-filter=ACM
  git diff --cached --name-only --diff-filter=ACM
  git ls-files --others --exclude-standard
}

if [ "$MODE" = "diff" ]; then
  CHANGED="$(changed_files | sort -u)"
fi

surface_glob() {
  case "$1" in
    shell)            printf '%s' '\.sh$|(^|/)\.githooks/' ;;
    python)           printf '%s' '\.py$' ;;
    js)               printf '%s' '\.js$' ;;
    yaml|yaml-syntax) printf '%s' '\.ya?ml$' ;;
    terraform-*)      printf '%s' '(^|/)terraform/|\.tflint\.hcl$|\.tf$' ;;
  esac
}

surface_touched() {
  case "$1" in
    shell)            grep -qE '\.sh$|(^|/)\.githooks/' || return 1 ;;
    python)           grep -q '\.py$' || return 1 ;;
    js)               grep -q '\.js$' || return 1 ;;
    yaml|yaml-syntax) grep -qE '\.ya?ml$' || return 1 ;;
    terraform-*)      grep -qE '(^|/)terraform/|\.tflint\.hcl$|\.tf$' || return 1 ;;
  esac
}

surface_files() {
  re="$(surface_glob "$1")"
  if [ "$MODE" = "full" ]; then
    find . -path './site' -prune -o -path './.git' -prune -o -type f -print 2>/dev/null | sed 's#^./##' | grep -E "$re" | sort
  else
    printf '%s\n' "$CHANGED" | grep -E "$re" | sort
  fi
}

status=0
for svc in $SURFACES; do
  if [ "$MODE" = "diff" ]; then
    if ! printf '%s\n' "$CHANGED" | surface_touched "$svc"; then
      printf '%s⏭  skip: %s (no matching files changed)%s\n' "$YELLOW" "$svc" "$NC"
      continue
    fi
    reason="changed"
  else
    reason="full"
  fi

  printf '%s== %s (%s) ==%s\n' "$BOLD" "$svc" "$reason" "$NC"
  if [ "$VERBOSE" -eq 1 ]; then
    surface_files "$svc" | sed 's#^#    #'
  fi
  if podman-compose -f containers/checks/compose.yml run --rm "$svc"; then
    printf '%s✅ %s (%s) passed%s\n' "$GREEN" "$svc" "$reason" "$NC"
  else
    printf '%s❌ %s (%s) failed%s\n' "$RED" "$svc" "$reason" "$NC"
    status=1
  fi
done

if [ "$MODE" = "diff" ] && [ -z "${CHANGED:-}" ]; then
  printf '%s⏭  no changed files detected — nothing to check (use --full for a whole-repo pass)%s\n' "$YELLOW" "$NC"
fi

if [ "$status" -eq 0 ]; then
  printf '%s✅ all checks passed%s\n' "$GREEN" "$NC"
else
  printf '%s❌ some checks failed%s\n' "$RED" "$NC"
fi
exit "$status"
