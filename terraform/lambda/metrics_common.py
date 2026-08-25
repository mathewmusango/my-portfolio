"""
Shared helpers for the metrics writer and reader Lambda functions.

Privacy guarantees (mirrors the site's "no tracking scripts, personal-data-free"
promise):
  - Geo comes ONLY from CloudFront's geo headers (country / country name / city /
    region) — the function never sees the visitor's IP or stores it.
  - The request body is whitelisted to a few known fields; anything else is dropped.
  - Referrers are reduced to their hostname.

Runtime: Python 3.12, stdlib + boto3 (bundled in the Lambda runtime).
"""

import base64
import json
import os

ALLOWED_ORIGIN = os.environ.get("ALLOWED_ORIGIN", "*")

MAX_BODY_BYTES = 2048

GEO_FIELDS = {
    "country": "cloudfront-viewer-country",
    "country_name": "cloudfront-viewer-country-name",
    "city": "cloudfront-viewer-city",
    "region": "cloudfront-viewer-region",
}


def _hostname(url):
    """Host (and port) of a URL — used to compare Origin/Referer exactly."""
    try:
        from urllib.parse import urlparse

        return (urlparse(url).netloc or "").lower()
    except Exception:
        return ""


def origin_allowed(event):
    """The request must come from the allowed site origin.

    Only the site (whose Origin/Referer matches ALLOWED_ORIGIN) may call the
    API; requests with no Origin/Referer are rejected — this is a public beacon
    by design, but nothing other than the site should reach it. CloudFront/WAF
    enforces the same rule at the edge in production (defense in depth).
    """
    if ALLOWED_ORIGIN == "*":
        return True
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    allowed_host = _hostname(ALLOWED_ORIGIN)
    return (
        _hostname(headers.get("origin", "")) == allowed_host
        or _hostname(headers.get("referer", "")) == allowed_host
    )


def headers(extra=None):
    h = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type,X-Metrics-Type",
    }
    if extra:
        h.update(extra)
    return h


def response(status, body=None, extra=None):
    return {
        "statusCode": status,
        "headers": headers(extra),
        "body": json.dumps(body) if body is not None else "",
        "isBase64Encoded": False,
    }


def geo(event):
    """Pull geo from CloudFront headers only — no IPs are ever persisted."""
    req_headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    return {
        field: req_headers.get(header, "unknown")
        for field, header in GEO_FIELDS.items()
    }


def decode_body(event):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        try:
            body = base64.b64decode(body).decode("utf-8", "replace")
        except Exception:
            return None
    if len(body.encode("utf-8")) > MAX_BODY_BYTES:
        return None
    try:
        data = json.loads(body)
    except (ValueError, TypeError):
        return None
    return data if isinstance(data, dict) else None
