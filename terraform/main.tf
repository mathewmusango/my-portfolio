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

resource "aws_cloudfront_distribution" "site" {
  count               = var.enable_site ? 1 : 0
  enabled             = true
  comment             = "${local.name_prefix}-site"
  default_root_object = "index.html"
  http_version        = "http2and3"
  price_class         = var.price_class
  tags                = local.tags
  is_ipv6_enabled     = true

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
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
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
  extra_allowed_origins = var.enable_site ? ["https://${aws_cloudfront_distribution.site[0].domain_name}"] : []
  event_retention_days  = var.event_retention_days
  price_class           = var.price_class
  enable_cloudfront     = var.enable_cloudfront
  enable_vpc            = var.enable_vpc
  enable_waf            = var.enable_waf
  waf_allowed_host      = var.waf_allowed_host
  tags                  = local.tags
}
