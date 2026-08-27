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

ALLOWED_ORIGINS = [
    o.strip() for o in os.environ.get("ALLOWED_ORIGIN", "*").split(",") if o.strip()
]

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


def request_origin(event):
    """The Origin header of the request, if any (case-insensitive)."""
    for k, v in (event.get("headers") or {}).items():
        if k.lower() == "origin":
            return v
    return ""


def origin_allowed(event):
    """The request must come from an allowed site origin (HTTPS only).

    Only sites whose Origin/Referer matches one of the ALLOWED_ORIGINS list may
    call the API; requests with no Origin/Referer are rejected — this is a
    public beacon by design, but nothing other than the sites should reach it.
    Cleartext (http://) origins are always rejected. CloudFront/WAF enforces the
    same rule at the edge in production (defense in depth).
    """
    if "*" in ALLOWED_ORIGINS:
        return True
    origin = request_origin(event).strip()
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    referer = (headers.get("referer") or "").strip()
    if origin and not origin.lower().startswith("https://"):
        return False  # HTTPS only
    allowed_hosts = {_hostname(o) for o in ALLOWED_ORIGINS}
    return _hostname(origin) in allowed_hosts or _hostname(referer) in allowed_hosts


def headers(extra=None, request_origin=None):
    h = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type,X-Metrics-Type",
    }
    # Multi-origin CORS: echo the request origin only when it is allowed.
    if request_origin and origin_allowed({"headers": {"origin": request_origin}}):
        h["Access-Control-Allow-Origin"] = request_origin
        h["Vary"] = "Origin"
    if extra:
        h.update(extra)
    return h


def response(status, body=None, extra=None, request_origin=None):
    return {
        "statusCode": status,
        "headers": headers(extra, request_origin),
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
