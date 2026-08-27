"""
Metrics reader — GET /summary (aggregate) and GET /health (uptime probe).

Least privilege: this function's role grants dynamodb:Scan only (no writes).
The writer function (metrics_writer.py) owns all writes.
"""

import os
import time
from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal

import boto3

from metrics_common import origin_allowed, request_origin, response

TABLE_NAME = os.environ["TABLE_NAME"]

table = boto3.resource("dynamodb").Table(TABLE_NAME)


def _summary():
    """Aggregate the last SCAN_LIMIT events in memory. Fine for portfolio-scale
    traffic; the read-optimized follow-up replaces this with a counters table
    fed by DynamoDB Streams."""
    scan_limit = 5000
    items = []
    last = None
    while True:
        kwargs = {"Limit": 1000}
        if last:
            kwargs["ExclusiveStartKey"] = last
        resp = table.scan(**kwargs)
        items.extend(resp.get("Items", []))
        last = resp.get("LastEvaluatedKey")
        if not last or len(items) >= scan_limit:
            break

    def count(key, exclude=None, only=None):
        counts = {}
        for item in items:
            if only and item.get("type") != only:
                continue
            k = item.get(key, "unknown")
            if exclude and k in exclude:
                continue
            counts[k] = counts.get(k, 0) + 1
        return dict(sorted(counts.items(), key=lambda kv: -kv[1]))

    # Referrers — hostname only; empty referrer = direct visit.
    by_ref = {}
    for item in items:
        ref = item.get("ref") or "(direct)"
        by_ref[ref] = by_ref.get(ref, 0) + 1
    by_ref = dict(sorted(by_ref.items(), key=lambda kv: -kv[1]))

    # Time-of-day + weekday from the stored timestamp.
    by_hour = {}
    by_day = {}
    for item in items:
        ts = item.get("ts")
        if isinstance(ts, (int, float, Decimal)):
            dt = datetime.fromtimestamp(float(ts), tz=timezone.utc)
            by_hour[dt.hour] = by_hour.get(dt.hour, 0) + 1
            by_day[dt.strftime("%a")] = by_day.get(dt.strftime("%a"), 0) + 1
    by_hour = {str(h): by_hour[h] for h in sorted(by_hour)}
    by_day = {d: by_day.get(d, 0) for d in ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")}

    # Devices (coarse class; old events without it are excluded).
    by_device = count("device", exclude={"unknown"})

    # CTA clicks — target per click event.
    clicks = {}
    for item in items:
        if item.get("type") == "click":
            t = item.get("target", "unknown")
            clicks[t] = clicks.get(t, 0) + 1
    clicks = dict(sorted(clicks.items(), key=lambda kv: -kv[1]))

    # Core Web Vitals — latest value per metric (a snapshot of the most recent
    # visitor experience rather than an average across all devices/connections).
    vitals = {}
    for item in items:
        if item.get("type") == "webvitals":
            m = item.get("metric")
            ts = item.get("ts") or 0
            value = item.get("value")
            if isinstance(value, Decimal):
                value = float(value)  # DynamoDB returns Decimal — make it JSON-safe
            if m and (m not in vitals or ts > vitals[m][0]):
                vitals[m] = (ts, value)
    vitals = {m: v[1] for m, v in vitals.items()}

    # Page load timing — average TTFB / DOM ready / full load.
    timing_acc = {}
    timing_n = 0
    for item in items:
        if item.get("type") == "timing":
            timing_n += 1
            for k in ("ttfb", "dcl", "load"):
                v = item.get(k)
                if isinstance(v, (int, float, Decimal)):
                    timing_acc[k] = timing_acc.get(k, 0) + v
    timing = {k: int(round(v / timing_n)) for k, v in timing_acc.items()} if timing_n else {}

    # Visitors + sessions: group events by anonymous visitor id; a session
    # breaks when the gap between events exceeds 30 minutes.
    per_visitor = defaultdict(list)
    for item in items:
        v = item.get("visitor")
        if v:
            per_visitor[v].append(item.get("ts") or 0)
    unique = len(per_visitor)
    returning = sum(1 for tl in per_visitor.values() if len(tl) > 1)

    sessions = []
    for tl in per_visitor.values():
        tl.sort()
        start = prev = tl[0]
        pages = 1
        for t in tl[1:]:
            if t - prev > 1800:
                sessions.append((start, prev, pages))
                start = t
                pages = 1
            else:
                pages += 1
            prev = t
        sessions.append((start, prev, pages))

    sess_count = len(sessions)
    pages_per_session = round(sum(s[2] for s in sessions) / sess_count, 1) if sess_count else 0
    durations = [s[1] - s[0] for s in sessions if s[1] > s[0]]
    avg_duration = int(sum(durations) / len(durations)) if durations else 0
    bounce = round(sum(1 for s in sessions if s[2] == 1) / sess_count * 100) if sess_count else 0

    return {
        "total": len(items),
        "by_country": count("country"),
        "by_page": count("page", only="pageview"),
        "by_lang": count("lang"),
        "by_ref": by_ref,
        "by_hour": by_hour,
        "by_day": by_day,
        "by_device": by_device,
        "by_type": count("type"),
        "clicks": clicks,
        "vitals": vitals,
        "timing": timing,
        "visitors": {
            "unique": unique,
            "returning": returning,
            "returning_pct": round(returning / unique * 100) if unique else 0,
        },
        "sessions": {
            "count": sess_count,
            "pages_per_session": pages_per_session,
            "avg_duration": avg_duration,
            "bounce": bounce,
        },
        "generated_at": int(time.time()),
    }


def _views(page):
    """Count pageview events for one page via the page-date GSI (no full scan).
    Timing/web-vitals/click events carry the page too — filter to pageviews so
    the counter increments by exactly one per page load."""
    count = 0
    last = None
    while True:
        kwargs = {
            "IndexName": "page-date-index",
            "KeyConditionExpression": "page = :p",
            # "type" is a reserved keyword — alias it.
            "FilterExpression": "#t = :t",
            "ExpressionAttributeNames": {"#t": "type"},
            "ExpressionAttributeValues": {":p": page, ":t": "pageview"},
            "Select": "COUNT",
            "Limit": 1000,
        }
        if last:
            kwargs["ExclusiveStartKey"] = last
        resp = table.query(**kwargs)
        count += resp.get("Count", 0)
        last = resp.get("LastEvaluatedKey")
        if not last:
            break
    return count


def handler(event, context):
    path = event.get("rawPath", "/")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")

    # /health is exempt — uptime probes have no Origin/Referer and return no data.
    if path != "/health" and not origin_allowed(event):
        return response(403, {"error": "forbidden origin"})

    if path == "/health":
        return response(200, {
            "status": "ok",
            "service": "my-portfolio-metrics",
            "table": TABLE_NAME,
        }, request_origin=request_origin(event))

    if path == "/views" and method == "GET":
        params = event.get("queryStringParameters") or {}
        page = str(params.get("page") or "")[:255]
        if not page:
            return response(400, {"error": "missing page parameter"})
        return response(200, {
            "page": page,
            "views": _views(page),
        }, extra={"Cache-Control": "max-age=300"}, request_origin=request_origin(event))

    if path == "/summary" and method == "GET":
        return response(200, _summary(), extra={"Cache-Control": "max-age=300"}, request_origin=request_origin(event))

    return response(404, {"error": "not found"})
