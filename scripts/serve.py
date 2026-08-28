#!/usr/bin/env python3
"""Custom MkDocs dev-server entrypoint with a /health endpoint.

This replaces the plain `mkdocs serve` command so the site exposes a small
health endpoint that container orchestrators and monitors can probe.

Expected results
----------------
GET /health  -> HTTP 200, application/json
GET /healthz -> HTTP 200, application/json (k8s-style alias)

    {
      "status": "ok",
      "service": "my-portfolio",
      "version": "1.0.0",
      "mkdocs": "1.6.1",
      "uptime_seconds": 123,
      "checks": {
        "server": "ok"
      }
    }

Any other path is served by MkDocs exactly as before (unchanged behavior).

It also teaches the dev server to render the styled 500 page
(docs/500.md -> site/500/index.html) when a request actually errors,
mirroring how 404.html is served.

Usage:
    python serve.py [--dev-addr HOST:PORT]
"""

import json
import os
import sys
import time

from mkdocs import __version__ as mkdocs_version
from mkdocs.commands.serve import serve
from mkdocs.livereload import LiveReloadServer

SERVICE_NAME = "my-portfolio"
SERVICE_VERSION = "1.0.0"
HEALTH_PATHS = ("/health", "/healthz")

_original_init = LiveReloadServer.__init__


def _health_payload(started_at: float) -> bytes:
    payload = {
        "status": "ok",
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "mkdocs": mkdocs_version,
        "uptime_seconds": int(time.time() - started_at),
        "checks": {
            "server": "ok",
        },
    }
    return json.dumps(payload, indent=2).encode("utf-8")


# mkdocs serve looks for site/500.html when a request errors, but a 500 page
# written in markdown builds to site/500/index.html instead. Intercept the
# error_handler so a real 500 also renders the styled 500 page.
def _patch_error_handler():
    def _get(self):
        return self.__dict__.get("_error_handler", lambda code: None)

    def _set(self, value):
        original = value

        def wrapped(code):
            content = original(code)
            if content is not None or code != 500:
                return content
            page = os.path.join(self.root, "500", "index.html")
            if os.path.isfile(page):
                with open(page, "rb") as f:
                    return f.read()
            return content

        self.__dict__["_error_handler"] = wrapped

    LiveReloadServer.error_handler = property(_get, _set)


_patch_error_handler()


def _patched_init(self, *args, **kwargs):
    _original_init(self, *args, **kwargs)
    original_app = self.get_app()
    started_at = time.time()

    def app(environ, start_response):
        path = environ.get("PATH_INFO", "").rstrip("/") or "/"
        if path in HEALTH_PATHS:
            body = _health_payload(started_at)
            start_response(
                "200 OK",
                [
                    ("Content-Type", "application/json; charset=utf-8"),
                    ("Content-Length", str(len(body))),
                    ("Cache-Control", "no-store"),
                ],
            )
            return [body]
        return original_app(environ, start_response)

    self.set_app(app)


LiveReloadServer.__init__ = _patched_init


def _parse_dev_addr(argv):
    if "--dev-addr" in argv:
        i = argv.index("--dev-addr")
        host, _, port = argv[i + 1].partition(":")
        return host, int(port or 8000)
    return "0.0.0.0", 8000


if __name__ == "__main__":
    host, port = _parse_dev_addr(sys.argv[1:])
    serve(dev_addr=f"{host}:{port}")
