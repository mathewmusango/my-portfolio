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

# ---------------------------------------------------------------------------
# Site — private S3 bucket + CloudFront via OAC, serving the static site at /.
# The resources live in ./modules/site; this root only wires the products.
# ---------------------------------------------------------------------------
module "site" {
  source                     = "./modules/site"
  project                    = var.project
  environment                = var.environment
  tags                       = var.tags
  enable_site                = var.enable_site
  price_class                = var.price_class
  response_headers_policy_id = aws_cloudfront_response_headers_policy.site_headers.id
}

moved {
  from = aws_s3_bucket.site[0]
  to   = module.site.aws_s3_bucket.site[0]
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.site[0]
  to   = module.site.aws_s3_bucket_server_side_encryption_configuration.site[0]
}

moved {
  from = aws_s3_bucket_public_access_block.site[0]
  to   = module.site.aws_s3_bucket_public_access_block.site[0]
}

moved {
  from = aws_cloudfront_origin_access_control.site[0]
  to   = module.site.aws_cloudfront_origin_access_control.site[0]
}

moved {
  from = aws_s3_bucket_policy.site[0]
  to   = module.site.aws_s3_bucket_policy.site[0]
}

moved {
  from = aws_cloudfront_distribution.site[0]
  to   = module.site.aws_cloudfront_distribution.site[0]
}

moved {
  from = aws_cloudfront_function.site_index[0]
  to   = module.site.aws_cloudfront_function.site_index[0]
}

moved {
  from = aws_cloudfront_function.site_error_pages[0]
  to   = module.site.aws_cloudfront_function.site_error_pages[0]
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
  extra_allowed_origins      = var.enable_site ? ["https://${module.site.distribution_domain_name}"] : []
  event_retention_days       = var.event_retention_days
  price_class                = var.price_class
  enable_cloudfront          = var.enable_cloudfront
  enable_vpc                 = var.enable_vpc
  enable_waf                 = var.enable_waf
  response_headers_policy_id = aws_cloudfront_response_headers_policy.site_headers.id
  tags                       = local.tags
}
