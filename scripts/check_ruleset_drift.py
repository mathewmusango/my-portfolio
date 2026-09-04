"""Compare an as-code ruleset file with the live GitHub ruleset (drift check).

Usage: check_ruleset_drift.py <as-code.json> <live.json>

Exits 0 when the rulesets match after normalization; prints the canonical
forms and exits 1 when they drift.
"""

import json
import sys

# Fields GitHub adds at runtime that are not part of the config-as-code.
RUNTIME_KEYS = {
    "id",
    "source_type",
    "source",
    "updated_at",
    "created_at",
    "node_id",
    "url",
    "html_url",
    "_links",
    "current_user_can_bypass",
}


def _dump(obj):
    return json.dumps(obj, sort_keys=True)


def _canonical(obj):
    """Recursively normalize: drop runtime keys and empty/null values, and
    make list order insignificant (rules/checks/bypass order doesn't matter)."""
    if isinstance(obj, dict):
        return {
            key: _canonical(value)
            for key, value in obj.items()
            if key not in RUNTIME_KEYS and value not in (None, [], {})
        }
    if isinstance(obj, list):
        return sorted((_canonical(item) for item in obj), key=_dump)
    return obj


def main():
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    with open(sys.argv[1], encoding="utf-8") as handle:
        as_code = json.load(handle)
    with open(sys.argv[2], encoding="utf-8") as handle:
        live = json.load(handle)
    as_code_norm = _canonical(as_code)
    live_norm = _canonical(live)
    if as_code_norm == live_norm:
        print("match")
        return 0
    print("drift:")
    print("file:", _dump(as_code_norm))
    print("live:", _dump(live_norm))
    return 1


if __name__ == "__main__":
    sys.exit(main())
