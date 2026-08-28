#!/usr/bin/env sh
# Run the local checks against CHANGED files only (pre-commit friendly).
# Whole-repo passes stay in check-compose.yaml (which mirrors CI exactly);
# this is the fast feedback loop for the commit stage. Reuses the same tool
# images as check-compose.yaml. css/html/md run on the host python3/ruby.
#
# Usage:
#   scripts/check-changed.sh            # staged + unstaged vs HEAD
#   scripts/check-changed.sh --cached   # staged only (pre-commit hook)
#
# Install as the git pre-commit hook:
#   git config core.hooksPath .githooks

set -eu

# shellcheck disable=SC1007  # CDPATH= cd is the intentional empty-CD cd idiom
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

if [ "${1:-}" = "--cached" ]; then
  FILES="$(git diff --cached --name-only --diff-filter=ACM)"
else
  FILES="$(git diff --name-only --diff-filter=ACM; git diff --cached --name-only --diff-filter=ACM)"
fi

if [ -z "$FILES" ]; then
  echo "no changed files — nothing to check"
  exit 0
fi

POD="podman run --rm -v $ROOT:/repo:ro -w /repo"

SH_FILES="$(printf '%s\n' "$FILES" | grep '\.sh$' || true)"
PY_FILES="$(printf '%s\n' "$FILES" | grep '\.py$' || true)"
JS_FILES="$(printf '%s\n' "$FILES" | grep '\.js$' || true)"
CSS_FILES="$(printf '%s\n' "$FILES" | grep '\.css$' || true)"
HTML_FILES="$(printf '%s\n' "$FILES" | grep '\.html$' || true)"
MD_FILES="$(printf '%s\n' "$FILES" | grep '\.md$' || true)"

if [ -n "$SH_FILES" ]; then
  echo "== shellcheck (changed) =="
  printf '%s\n' "$SH_FILES" | xargs "$POD" docker.io/koalaman/shellcheck-alpine shellcheck -S warning
fi

if [ -n "$PY_FILES" ]; then
  echo "== ruff (changed) =="
  printf '%s\n' "$PY_FILES" | xargs "$POD" ghcr.io/astral-sh/ruff ruff check
fi

if [ -n "$JS_FILES" ]; then
  echo "== node --check (changed) =="
  printf '%s\n' "$JS_FILES" | while IFS= read -r f; do
    "$POD" docker.io/library/node:alpine node --check "$f"
  done
fi

if [ -n "$CSS_FILES" ]; then
  echo "== css (changed) =="
  python3 scripts/check_css.py $CSS_FILES
fi

if [ -n "$HTML_FILES" ]; then
  echo "== html (changed) =="
  python3 scripts/check_html.py $HTML_FILES
fi

if [ -n "$MD_FILES" ]; then
  echo "== md (changed) =="
  ruby scripts/check_md.rb $MD_FILES
fi

echo "changed-files checks passed"
