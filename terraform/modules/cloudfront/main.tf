resource "aws_cloudfront_origin_access_control" "this" {
  count                             = var.enable ? 1 : 0
  name                              = var.oac_name
  description                       = "OAC — private origin bucket, CloudFront-only access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"

  lifecycle {
    ignore_changes = [description]
  }
}

data "aws_iam_policy_document" "oac" {
  count = var.enable ? 1 : 0

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.origin_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this[0].arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.enable ? 1 : 0
  bucket = var.origin_bucket_id
  policy = data.aws_iam_policy_document.oac[0].json
}

resource "aws_cloudfront_distribution" "this" {
  count               = var.enable ? 1 : 0
  enabled             = true
  comment             = var.name
  default_root_object = var.default_root_object
  http_version        = "http2and3"
  price_class         = var.price_class
  tags                = var.tags
  is_ipv6_enabled     = true
  # checkov:skip=CKV_AWS_86:Access logging skipped for a low-traffic personal site (deliberate)
  # checkov:skip=CKV_AWS_374:Geo restriction deliberately none — the site is a public portfolio
  # checkov:skip=CKV_AWS_310:Single S3 origin — no secondary for failover (personal site)
  # checkov:skip=CKV_AWS_68:WAF excluded — outside the Free Tier (user constraint)
  # checkov:skip=CKV_AWS_174:Default cert is TLS 1.2+ by AWS guarantee; no custom domain for ACM (checkov wants ACM)
  # checkov:skip=CKV2_AWS_42:No custom domain — default CloudFront cert is TLS 1.2+ by AWS guarantee
  # checkov:skip=CKV2_AWS_47:WAF excluded — outside the Free Tier (user constraint)

  origin {
    domain_name              = var.origin_bucket_regional_domain_name
    origin_id                = var.name
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
  }

  default_cache_behavior {
    target_origin_id           = var.name
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    allowed_methods            = var.allowed_methods
    cached_methods             = var.cached_methods
    cache_policy_id            = var.cache_policy_id
    response_headers_policy_id = var.response_headers_policy_id

    dynamic "function_association" {
      for_each = var.enable ? { for f in var.functions : f.key => f } : {}
      content {
        event_type   = function_association.value.event_type
        function_arn = aws_cloudfront_function.this[function_association.key].arn
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = var.error_responses
    content {
      error_code         = custom_error_response.value.error_code
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudfront_function" "this" {
  for_each = var.enable ? { for f in var.functions : f.key => f } : {}

  name    = each.value.name
  runtime = "cloudfront-js-2.0"
  comment = each.value.comment
  publish = true
  code    = each.value.code
}
