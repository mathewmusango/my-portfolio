provider "aws" {
  region = var.aws_region

  # Portability: credentials + endpoints come from the standard AWS env vars
  # (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_DEFAULT_REGION, and
  # AWS_ENDPOINT_URL for local Ministack/LocalStack). No endpoints are
  # hardcoded here — real AWS needs nothing extra; local dev sources
  # ministack.env (see README).
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  # Every taggable resource carries the environment (staging/prod) — merged
  # from the base tags so nothing needs to be passed per-env.
  tags = merge(var.tags, { environment = var.environment })
}

# ---------------------------------------------------------------------------
# Site — private S3 bucket + CloudFront via OAC, serving the static site at /
# (content lives at the bucket root; NOT a public bucket — see the OAC policy).
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "site" {
  count  = var.enable_site ? 1 : 0
  bucket = "${local.name_prefix}-site"
  tags   = local.tags
  # checkov:skip=CKV_AWS_21:Versioning declined by user (2026-08-28) — site content redeploys from the repo
  # checkov:skip=CKV_AWS_144:Cross-region replication = extra cost — single-region personal site (free tier)
  # checkov:skip=CKV2_AWS_62:No S3 event consumers — nothing triggers on bucket events
  # checkov:skip=CKV_AWS_145:KMS (aws:kms, AWS-managed key) is set via the separate SSE resource — graph check can't resolve the count-gated association
  # checkov:skip=CKV_AWS_18:Access logging skipped — low-traffic personal site (deliberate)
  # checkov:skip=CKV2_AWS_61:No lifecycle needed — sync --delete self-manages content; no expiry/transition use case
  # checkov:skip=CKV2_AWS_6:Public access block exists (aws_s3_bucket_public_access_block.site) — graph check can't resolve the count-gated resource
}

# KMS encryption with the AWS-managed key (aws:kms, no kms_key_id) — free, and
# satisfies CKV_AWS_145 without a $1/mo CMK.
resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  count  = var.enable_site ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  rule {
    apply_server_side_encryption_by_default {
      # AWS-managed key (alias/aws/s3) — KMS encryption at zero cost, no CMK.
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "site" {
  count                   = var.enable_site ? 1 : 0
  bucket                  = aws_s3_bucket.site[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "site" {
  count                             = var.enable_site ? 1 : 0
  name                              = "${local.name_prefix}-site-oac"
  description                       = "OAC — private site bucket, CloudFront-only access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_iam_policy_document" "site_oac" {
  count = var.enable_site ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site[0].arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  count  = var.enable_site ? 1 : 0
  bucket = aws_s3_bucket.site[0].id
  policy = data.aws_iam_policy_document.site_oac[0].json
}

# Security headers at the edge (free) — attached to both distributions. No CSP:
# the site runs inline scripts (language switcher, metrics beacon) which a CSP
# would break; the safe trio + HSTS is the free win.
resource "aws_cloudfront_response_headers_policy" "site_headers" {
  name    = "${local.name_prefix}-site-headers"
  comment = "Security headers (nosniff, frame DENY, referrer, HSTS) — no CSP (inline scripts)"

  security_headers_config {
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
      override     = true
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "site" {
  count               = var.enable_site ? 1 : 0
  enabled             = var.site_enabled
  comment             = "${local.name_prefix}-site"
  default_root_object = "index.html"
  http_version        = "http2and3"
  price_class         = var.price_class
  tags                = local.tags
  is_ipv6_enabled     = true
  # checkov:skip=CKV_AWS_86:Access logging skipped for a low-traffic personal site (deliberate)
  # checkov:skip=CKV_AWS_374:Geo restriction deliberately none — the site is a public portfolio
  # checkov:skip=CKV_AWS_310:Single S3 origin — no secondary for failover (personal site)
  # checkov:skip=CKV_AWS_68:WAF excluded — outside the Free Tier (user constraint)
  # checkov:skip=CKV_AWS_174:Default cert is TLS 1.2+ by AWS guarantee; no custom domain for ACM (checkov wants ACM)
  # checkov:skip=CKV2_AWS_42:No custom domain — default CloudFront cert is TLS 1.2+ by AWS guarantee
  # checkov:skip=CKV2_AWS_47:WAF excluded — outside the Free Tier (user constraint)

  origin {
    domain_name              = aws_s3_bucket.site[0].bucket_regional_domain_name
    origin_id                = "${local.name_prefix}-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site[0].id
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_prefix}-site"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    # Managed policy: CachingOptimized
    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.site_headers.id

    # S3 doesn't resolve directory URLs (/metrics/ -> metrics/index.html) the
    # way GitHub Pages does — rewrite them at the edge.
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.site_index[0].arn
    }

    # Localized 500 error pages (en/es/zh) — redirect based on the request locale.
    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.site_error_pages[0].arn
    }
  }

  # Error pages — 403/404 to the root 404.html (the only locale-agnostic one);
  # 500s are LOCALIZED (500/, es/500/, zh/500/) -> handled by the
  # site_error_pages viewer-response function below.
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# Directory-URL resolution for the S3 origin: mkdocs builds /metrics/index.html
# and links to /metrics/ — append index.html to trailing-slash requests.
resource "aws_cloudfront_function" "site_index" {
  count   = var.enable_site ? 1 : 0
  name    = "${local.name_prefix}-site-index"
  runtime = "cloudfront-js-2.0"
  comment = "Resolve directory URLs (/path/ -> /path/index.html) on the S3 origin"
  publish = true
  code    = <<-EOT
function handler(event) {
  var request = event.request;
  var uri = request.uri;
  if (uri.endsWith('/')) {
    request.uri = uri + 'index.html';
  } else if (uri.indexOf('.', uri.lastIndexOf('/')) === -1) {
    // Extension-less last segment -> directory URL without the trailing slash
    // (/es/about -> /es/about/index.html). Files (logo.jpg, resume.pdf, …)
    // keep a dot after the last slash and pass through untouched.
    request.uri = uri + '/index.html';
  }
  return request;
}
EOT
}

# Localized 500 error pages — the 500 pages are per-locale (500/, es/500/,
# zh/500/), so on a 500 response we redirect to the request's locale page.
resource "aws_cloudfront_function" "site_error_pages" {
  count   = var.enable_site ? 1 : 0
  name    = "${local.name_prefix}-site-error-pages"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect 500 responses to the localized 500 page (en/es/zh)"
  publish = true
  code    = <<-EOT
function handler(event) {
  var response = event.response;
  if (response.statusCode !== '500') {
    return response;
  }
  var uri = event.request.uri || '/';
  var locale = '';
  var m = uri.match(/^\/(es|zh)(\/|$)/);
  if (m) { locale = m[1] + '/'; }
  return {
    statusCode: 302,
    statusDescription: 'Found',
    headers: {
      location: { value: '/' + locale + '500/' },
      'content-type': { value: 'text/html; charset=utf-8' },
    },
  };
}
EOT
}

# ---------------------------------------------------------------------------
# Metrics — API Gateway → Lambda → DynamoDB (+ geo CloudFront / optional WAF),
# gated OFF until the metrics phase (enable_metrics). Lives in ./modules/metrics.
# ---------------------------------------------------------------------------
module "metrics" {
  source         = "./modules/metrics"
  count          = var.enable_metrics ? 1 : 0
  aws_region     = var.aws_region
  project        = var.project
  environment    = var.environment
  allowed_origin = var.allowed_origin
  # The site's own CloudFront domain is always allowed (auto-derived, HTTPS).
  extra_allowed_origins      = var.enable_site ? ["https://${aws_cloudfront_distribution.site[0].domain_name}"] : []
  event_retention_days       = var.event_retention_days
  price_class                = var.price_class
  enable_cloudfront          = var.enable_cloudfront
  enable_vpc                 = var.enable_vpc
  enable_waf                 = var.enable_waf
  response_headers_policy_id = aws_cloudfront_response_headers_policy.site_headers.id
  tags                       = local.tags
}
