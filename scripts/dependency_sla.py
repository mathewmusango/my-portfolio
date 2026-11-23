"""Fail when an open Dependabot alert has outlived its remediation window."""

import argparse
import datetime
import json
import pathlib
import sys

WINDOWS = {"critical": 7, "high": 30, "medium": 90}


def age_days(created, today):
    stamp = datetime.datetime.fromisoformat(created)
    return (today - stamp.date()).days


def offenders(alerts, today):
    found = []
    for alert in alerts:
        severity = (alert.get("security_advisory") or {}).get("severity", "")
        window = WINDOWS.get(severity)
        if window is None:
            continue
        days = age_days(alert["created_at"], today)
        if days > window:
            package = (alert.get("dependency") or {}).get("package", {}).get("name", "?")
            found.append((package, severity, days, window, alert.get("html_url", "")))
    return found


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("alerts", nargs="?", help="path to the alerts JSON")
    parser.add_argument("--today", help="YYYY-MM-DD (default: today)")
    args = parser.parse_args(argv)

    if not args.alerts:
        parser.print_help()
        return 2

    today = (
        datetime.date.fromisoformat(args.today)
        if args.today
        else datetime.datetime.now(tz=datetime.UTC).date()
    )
    alerts = json.loads(pathlib.Path(args.alerts).read_text(encoding="utf-8"))
    found = offenders(alerts, today)

    windows = ", ".join(f"{name} {days}d" for name, days in WINDOWS.items())
    for package, severity, days, window, url in found:
        print(f"{severity:<8} {package:<28} open {days}d, window {window}d  {url}")
    if found:
        print(f"\n{len(found)} alert(s) past the remediation window ({windows})")
        return 1

    print(f"no open alert is past its remediation window ({windows})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
