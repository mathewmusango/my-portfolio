provider "aws" {
  region = var.aws_region
}

locals {
  name_prefix     = "${var.project}-${var.environment}"
  primary_origins = var.allowed_origin == "" ? [] : [var.allowed_origin]
  primary_hosts   = var.allowed_origin == "" ? [] : [replace(replace(var.allowed_origin, "https://", ""), "http://", "")]
  site_origin     = try("https://${data.terraform_remote_state.site.outputs.distribution_domain_name}", "")
  extra_origins   = compact(concat(var.extra_allowed_origins, [local.site_origin]))
  metrics_origins = distinct(concat(local.primary_origins, local.extra_origins))
  allowed_hosts   = distinct(concat(local.primary_hosts, [for o in local.extra_origins : replace(replace(o, "https://", ""), "http://", "")]))
  tags            = merge(var.tags, { environment = var.environment })
}

data "terraform_remote_state" "site" {
  backend = "s3"
  config = {
    bucket  = var.site_state_bucket != "" ? var.site_state_bucket : "${var.project}-${var.environment}-tfstate"
    key     = "site/terraform.tfstate"
    region  = var.aws_region
    encrypt = true
  }
}

resource "aws_cloudfront_response_headers_policy" "metrics_headers" {
  name    = "${local.name_prefix}-metrics-headers"
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

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda"
  output_path = "${path.root}/lambda.zip"
}

module "vpc" {
  source              = "../../modules/vpc"
  security_group_name = "${local.name_prefix}-metrics-lambda-sg"
  tags                = local.tags
  enable              = var.enable_vpc
  cidr_block          = "10.200.0.0/16"
  subnet_count        = 2
  gateway_endpoints = {
    dynamodb = "com.amazonaws.${var.aws_region}.dynamodb"
  }
  interface_endpoints = {
    logs = {
      service_name        = "com.amazonaws.${var.aws_region}.logs"
      private_dns_enabled = true
    }
  }
}

module "dynamodb" {
  source        = "../../modules/dynamodb"
  name          = "${local.name_prefix}-metrics"
  tags          = local.tags
  hash_key      = "date"
  range_key     = "sk"
  ttl_attribute = "ttl"
  attributes = [
    { name = "date", type = "S" },
    { name = "sk", type = "S" },
    { name = "page", type = "S" },
  ]
  global_secondary_indexes = [
    { name = "page-date-index", hash_key = "page", range_key = "date", projection_type = "ALL" },
  ]
  deletion_protection = var.deletion_protection
}

module "lambda_writer" {
  source           = "../../modules/lambda"
  function_name    = "${local.name_prefix}-metrics-writer"
  role_name        = "${local.name_prefix}-metrics-writer-role"
  tags             = local.tags
  handler          = "metrics_writer.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment = {
    TABLE_NAME      = module.dynamodb.table_name
    EVENT_RETENTION = tostring(var.event_retention_days)
    ALLOWED_ORIGIN  = join(",", local.metrics_origins)
  }
  iam_policies = {
    dynamodb = {
      name = "${local.name_prefix}-metrics-writer-dynamodb"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect   = "Allow"
          Action   = ["dynamodb:PutItem"]
          Resource = module.dynamodb.table_arn
        }]
      })
    }
  }
  enable_vpc        = var.enable_vpc
  subnet_ids        = module.vpc.subnet_ids
  security_group_id = module.vpc.security_group_id
}

module "lambda_reader" {
  source           = "../../modules/lambda"
  function_name    = "${local.name_prefix}-metrics-reader"
  role_name        = "${local.name_prefix}-metrics-reader-role"
  tags             = local.tags
  handler          = "metrics_reader.handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  environment = {
    TABLE_NAME     = module.dynamodb.table_name
    ALLOWED_ORIGIN = join(",", local.metrics_origins)
  }
  iam_policies = {
    dynamodb = {
      name = "${local.name_prefix}-metrics-reader-dynamodb"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect = "Allow"
          Action = ["dynamodb:Scan", "dynamodb:Query"]
          Resource = [
            module.dynamodb.table_arn,
            "${module.dynamodb.table_arn}/index/*",
          ]
        }]
      })
    }
  }
  enable_vpc        = var.enable_vpc
  subnet_ids        = module.vpc.subnet_ids
  security_group_id = module.vpc.security_group_id
}

module "api_gateway" {
  source = "../../modules/api-gateway"
  name   = "${local.name_prefix}-metrics-api"
  tags   = local.tags
  cors = {
    allow_origins = local.metrics_origins
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Metrics-Type"]
    max_age       = 3600
  }
  integrations = {
    write = {
      lambda_invoke_arn    = module.lambda_writer.invoke_arn
      lambda_function_name = module.lambda_writer.function_name
    }
    read = {
      lambda_invoke_arn    = module.lambda_reader.invoke_arn
      lambda_function_name = module.lambda_reader.function_name
    }
  }
  routes = {
    post_event  = { route_key = "POST /event", integration_key = "write" }
    get_summary = { route_key = "GET /summary", integration_key = "read" }
    get_health  = { route_key = "GET /health", integration_key = "read" }
    get_views   = { route_key = "GET /views", integration_key = "read" }
  }
}

module "waf" {
  source          = "../../modules/waf"
  name            = "${local.name_prefix}-metrics-acl"
  tags            = local.tags
  enable          = var.enable_waf
  allowed_host    = try(local.allowed_hosts[0], "")
  rate_limit      = 300
  metric_name     = "metrics"
  association_arn = var.enable_waf ? aws_cloudfront_distribution.metrics[0].arn : null
}

resource "aws_cloudfront_origin_request_policy" "geo" {
  count   = var.enable_cloudfront ? 1 : 0
  name    = "${local.name_prefix}-metrics-geo"
  comment = "Forward CloudFront geo headers + CORS headers to the metrics API"

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "CloudFront-Viewer-Country",
        "CloudFront-Viewer-Country-Name",
        "CloudFront-Viewer-City",
        "CloudFront-Viewer-City-Name",
        "CloudFront-Viewer-Region",
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers",
        "Content-Type",
      ]
    }
  }
  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_distribution" "metrics" {
  count           = var.enable_cloudfront ? 1 : 0
  enabled         = true
  comment         = "${local.name_prefix}-metrics"
  price_class     = var.price_class
  tags            = local.tags
  is_ipv6_enabled = true
  # checkov:skip=CKV_AWS_86:Access logging skipped for a low-traffic personal site (deliberate)
  # checkov:skip=CKV_AWS_374:Geo restriction deliberately none — the metrics edge is public by design
  # checkov:skip=CKV_AWS_310:Single S3 origin — no secondary for failover (personal site)
  # checkov:skip=CKV_AWS_68:WAF excluded — outside the Free Tier (user constraint)
  # checkov:skip=CKV_AWS_305:API distribution (Gateway origin) — no default root object concept
  # checkov:skip=CKV_AWS_174:Default cert is TLS 1.2+ by AWS guarantee; no custom domain for ACM (checkov wants ACM)
  # checkov:skip=CKV2_AWS_42:No custom domain — default CloudFront cert is TLS 1.2+ by AWS guarantee
  # checkov:skip=CKV2_AWS_47:WAF excluded — outside the Free Tier (user constraint)

  origin {
    domain_name = replace(module.api_gateway.api_endpoint, "https://", "")
    origin_id   = "metrics-api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id           = "metrics-api"
    viewer_protocol_policy     = "redirect-to-https"
    compress                   = true
    allowed_methods            = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.geo[0].id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.metrics_headers.id
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.origin_gate[0].arn
    }
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudfront_function" "origin_gate" {
  count   = var.enable_cloudfront ? 1 : 0
  name    = "${local.name_prefix}-origin-gate"
  runtime = "cloudfront-js-2.0"
  comment = "Allow only the site origins (HTTPS); /health exempt (free WAF-equivalent)"
  publish = true
  code    = <<-EOT
function handler(event) {
  var request = event.request;

  // Uptime probes hit /health without Origin/Referer — always allow.
  if (request.uri === '/health') {
    return request;
  }

  var allowed = ['${join("', '", local.allowed_hosts)}'];

  function hdr(name) {
    var h = request.headers[name];
    return h ? h.value : '';
  }
  function ok(value) {
    if (!value) return false;
    if (value.indexOf('https://') !== 0) return false; // HTTPS only
    return allowed.indexOf(hostname(value)) !== -1;
  }

  if (ok(hdr('origin')) || ok(hdr('referer'))) {
    return request;
  }

  return {
    statusCode: 403,
    statusDescription: 'Forbidden',
    headers: { 'content-type': { value: 'text/plain' } },
    body: 'Forbidden',
  };
}

function hostname(value) {
  if (!value) return '';
  value = value.replace(/^[a-z]+:\/\//i, '');
  value = value.split('/')[0];
  value = value.split(':')[0];
  return value.toLowerCase();
}
EOT
}
