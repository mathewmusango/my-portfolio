"""
Metrics writer — POST /event: validate the payload and PutItem to DynamoDB.

Least privilege: this function's role grants dynamodb:PutItem only (no reads).
The reader function (metrics_reader.py) owns all reads.
"""

import os
import time
import uuid

import boto3
from decimal import Decimal

from metrics_common import decode_body, geo, headers, origin_allowed, request_origin, response

TABLE_NAME = os.environ["TABLE_NAME"]
RETENTION_DAYS = int(os.environ.get("EVENT_RETENTION", "90"))

table = boto3.resource("dynamodb").Table(TABLE_NAME)


def handler(event, context):
    if not origin_allowed(event):
        return response(403, {"error": "forbidden origin"})

    data = decode_body(event)
    if data is None:
        return response(400, {"error": "invalid or oversized payload"})

    now = int(time.time())
    page = str(data.get("page") or "/")[:255]
    lang = str(data.get("lang") or "en")[:8]
    ref = str(data.get("ref") or "")[:255]

    # Referrer → hostname only (privacy: no full URLs from other sites).
    ref_host = ref.split("/")[2] if ref.startswith(("http://", "https://")) else ""

    item = {
        "date": time.strftime("%Y-%m-%d", time.gmtime(now)),
        "sk": f"evt#{uuid.uuid4().hex}",
        "ts": now,
        "type": str(data.get("type") or "pageview")[:24],
        "page": page,
        "lang": lang,
        "ref": ref_host,
        "ttl": now + RETENTION_DAYS * 86400,
    }
    item.update(geo(event))

    # Optional whitelisted enrichment fields (from the beacon):
    #   visitor/device/target/metric — short strings
    #   value/ttfb/dcl/load          — numbers (web vitals, page timing)
    for field in ("visitor", "device", "target", "metric"):
        val = data.get(field)
        if val is not None:
            item[field] = str(val)[:64]
    for field in ("value", "ttfb", "dcl", "load"):
        val = data.get(field)
        if isinstance(val, (int, float)) and not isinstance(val, bool):
            # DynamoDB has no float type — Decimal(str()) keeps ints exact and
            # floats precise (the beacon already rounds CLS to 3 decimals).
            item[field] = Decimal(str(val))

    try:
        table.put_item(Item=item)
    except Exception as exc:  # pragma: no cover
        return response(500, {"error": f"write failed: {exc}"})

    # 204: the beacon never needs a body back
    return {
        "statusCode": 204,
        "headers": headers(request_origin=request_origin(event)),
        "body": "",
        "isBase64Encoded": False,
    }
