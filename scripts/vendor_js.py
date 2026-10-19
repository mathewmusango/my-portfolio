import argparse
import hashlib
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "scripts/vendor.json"
PACKAGE = ROOT / "package.json"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pinned_versions():
    return load_json(PACKAGE).get("devDependencies", {})


def uncovered_packages(deps, assets):
    return sorted(set(deps) - {asset["package"] for asset in assets})


def report(errors):
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        print(f"{len(errors)} vendored JS problem(s)", file=sys.stderr)
        return 1
    return 0


def check():
    deps = pinned_versions()
    assets = load_json(MANIFEST)["assets"]
    errors = []
    for asset in assets:
        package = asset["package"]
        pin = deps.get(package)
        if pin is None:
            errors.append(f"{package}: not pinned in package.json")
            continue
        if asset["version"] != pin:
            errors.append(
                f"{asset['destination']}: recorded version {asset['version']}"
                f" does not match the package.json pin {pin}"
            )
        path = ROOT / asset["destination"]
        if not path.is_file():
            errors.append(f"{asset['destination']}: missing")
            continue
        actual = sha256(path)
        if actual != asset["sha256"]:
            errors.append(
                f"{asset['destination']}: sha256 {actual}"
                f" does not match the recorded {asset['sha256']}"
            )
    for package in uncovered_packages(deps, assets):
        errors.append(f"{package}: pinned in package.json but not vendored")
    if errors:
        errors.append("run scripts/vendor_js.py --update to re-vendor")
        return report(errors)
    print(f"{len(assets)} vendored JS file(s) match package.json")
    return 0


def download(url, attempts=3):
    last_error = None
    for attempt in range(attempts):
        request = urllib.request.Request(url, headers={"User-Agent": "vendor-js"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.read()
        except OSError as error:
            last_error = error
            if attempt + 1 < attempts:
                time.sleep(2 * (attempt + 1))
    raise last_error


def update():
    deps = pinned_versions()
    manifest = load_json(MANIFEST)
    assets = manifest["assets"]
    errors = []
    for asset in assets:
        package = asset["package"]
        pin = deps.get(package)
        if pin is None:
            errors.append(f"{package}: not pinned in package.json")
            continue
        asset["version"] = pin
        url = f"{manifest['source']}/{package}@{pin}/{asset['source_path']}"
        data = download(url)
        destination = ROOT / asset["destination"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_name(destination.name + ".tmp")
        temporary.write_bytes(data)
        temporary.replace(destination)
        asset["sha256"] = hashlib.sha256(data).hexdigest()
        print(f"{asset['destination']}: {package} {pin} ({len(data)} bytes)")
    for package in uncovered_packages(deps, assets):
        errors.append(f"{package}: pinned in package.json but not vendored")
    if errors:
        return report(errors)
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"updated {len(assets)} vendored file(s)")
    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Verify or refresh the JavaScript vendored under docs/assets against package.json."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the vendored files against package.json (default)",
    )
    parser.add_argument(
        "--update",
        action="store_true",
        help="download the pinned versions and rewrite scripts/vendor.json",
    )
    args = parser.parse_args()
    return update() if args.update else check()


if __name__ == "__main__":
    sys.exit(main())
