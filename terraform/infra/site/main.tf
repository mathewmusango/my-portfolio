provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix = "${var.project}-${var.environment}"
  tags        = merge(var.tags, { environment = var.environment })

  functions = [
    {
      key        = "index"
      name       = "${local.name_prefix}-site-index"
      comment    = "Resolve directory URLs (/path/ -> /path/index.html) on the S3 origin"
      event_type = "viewer-request"
      code       = <<-EOT
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
    },
    {
      key        = "error_pages"
      name       = "${local.name_prefix}-site-error-pages"
      comment    = "Redirect 500 responses to the localized 500 page (en/es/zh)"
      event_type = "viewer-response"
      code       = <<-EOT
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
    },
  ]

  error_responses = [
    { error_code = 404, response_code = 404, response_page_path = "/404.html" },
    { error_code = 403, response_code = 404, response_page_path = "/404.html" },
  ]
}

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

module "s3" {
  source = "../../modules/s3"
  name   = "${local.name_prefix}-site"
  tags   = local.tags
  enable = var.enable_site
}

module "cloudfront" {
  source                             = "../../modules/cloudfront"
  name                               = "${local.name_prefix}-site"
  oac_name                           = "${local.name_prefix}-site-oac"
  tags                               = local.tags
  enable                             = var.enable_site
  price_class                        = var.price_class
  origin_bucket_id                   = module.s3.bucket_id
  origin_bucket_arn                  = module.s3.bucket_arn
  origin_bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  default_root_object                = "index.html"
  cache_policy_id                    = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  response_headers_policy_id         = aws_cloudfront_response_headers_policy.site_headers.id
  allowed_methods                    = ["GET", "HEAD", "OPTIONS"]
  cached_methods                     = ["GET", "HEAD"]
  functions                          = local.functions
  error_responses                    = local.error_responses
}
