#!/usr/bin/env sh
set -eu

# shellcheck disable=SC1007  # CDPATH= cd is the intentional empty-CD cd idiom
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE="containers/mkdocs/compose.yaml"

usage() {
  printf 'usage: %s {build|start|restart|stop}\n' "$0"
  printf 'build    build the dev image from containers/mkdocs/Dockerfile\n'
  printf 'start    start the dev container, without building\n'
  printf 'restart  recreate the dev container from the compose file\n'
  printf 'stop     stop the dev container\n'
  printf 'docs: scripts/README.md\n'
}

command -v podman-compose >/dev/null 2>&1 || {
  printf '%s\n' 'podman-compose is not on PATH' >&2
  exit 1
}

verb="${1:-}"
[ "$#" -le 1 ] || { usage >&2; exit 2; }

if [ -z "${PORTFOLIO_GIT_DIR:-}" ]; then
  git_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$git_dir" ]; then
    PORTFOLIO_GIT_DIR="$git_dir"
    export PORTFOLIO_GIT_DIR
  fi
fi

case "$verb" in
  build)     podman-compose -f "$COMPOSE" build ;;
  start)     podman-compose -f "$COMPOSE" up -d --no-build ;;
  restart)   podman-compose -f "$COMPOSE" up -d --no-build --force-recreate ;;
  stop)      podman-compose -f "$COMPOSE" stop ;;
  -h|--help) usage ;;
  *)         usage >&2; exit 2 ;;
esac
