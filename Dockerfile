# MkDocs development image for the cloud resume site
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies (git is required by the revision-date plugin)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
# Install dependencies first for better layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the site source
COPY mkdocs.yml .
COPY docs ./docs
COPY overrides ./overrides

# MkDocs dev server port
EXPOSE 8000

# Serve with live reload; bind to 0.0.0.0 so the port is reachable from the host
CMD ["mkdocs", "serve", "--dev-addr", "0.0.0.0:8000"]
