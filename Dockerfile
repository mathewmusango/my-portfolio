FROM node:22-slim AS js

WORKDIR /js

COPY package.json package-lock.json ./
COPY scripts/hooks/vendor.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund && \
    mkdir -p /vendor && \
    node -p 'Object.keys(require("./vendor.json")).join("\n")' > /tmp/vendor-list && \
    xargs -r -a /tmp/vendor-list cp --parents -t /vendor && \
    rm -rf node_modules /tmp/vendor-list

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt/archives,sharing=locked \
    apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip pip install --no-compile -r requirements.txt

COPY --from=js /vendor/node_modules ./node_modules

COPY mkdocs.yml .
COPY docs ./docs
COPY overrides ./overrides

EXPOSE 8000

CMD ["mkdocs", "serve", "--dev-addr", "0.0.0.0:8000"]
