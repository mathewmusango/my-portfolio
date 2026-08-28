locals {
  name_prefix = "${var.project}-${var.environment}"
  # Primary origin may be empty (staging: the site's own distro is auto-added via
  # extra_allowed_origins) — filter it out so CORS/origin-gate stay clean.
  primary_origins = var.allowed_origin == "" ? [] : [var.allowed_origin]
  primary_hosts   = var.allowed_origin == "" ? [] : [replace(replace(var.allowed_origin, "https://", ""), "http://", "")]
  # All origins this environment may send from (primary + extra, HTTPS only).
  metrics_origins = distinct(concat(local.primary_origins, var.extra_allowed_origins))
  allowed_hosts   = distinct(concat(local.primary_hosts, [for o in var.extra_allowed_origins : replace(replace(o, "https://", ""), "http://", "")]))
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_prefix_list" "logs" {
  count = var.enable_vpc ? 1 : 0
  name  = "com.amazonaws.${var.aws_region}.logs"
}

# ---------------------------------------------------------------------------
# Private VPC — the Lambdas live here with NO internet path. They reach
# DynamoDB (Gateway endpoint) and CloudWatch Logs (Interface endpoint) only.
# Real AWS only; gated off for Ministack (no real VPC).
# ---------------------------------------------------------------------------
resource "aws_vpc" "metrics" {
  count                = var.enable_vpc ? 1 : 0
  cidr_block           = "10.200.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.tags
}

resource "aws_subnet" "metrics" {
  count             = var.enable_vpc ? 2 : 0
  vpc_id            = aws_vpc.metrics[0].id
  cidr_block        = "10.200.${count.index}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = var.tags
}

resource "aws_security_group" "metrics_lambda" {
  count       = var.enable_vpc ? 1 : 0
  vpc_id      = aws_vpc.metrics[0].id
  name        = "${local.name_prefix}-metrics-lambda-sg"
  description = "Lambda egress to VPC endpoints only; the logs endpoint accepts 443 from this SG"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_prefix_list.logs[0].id]
  }
  tags = var.tags
}

resource "aws_vpc_endpoint" "metrics_dynamodb" {
  count             = var.enable_vpc ? 1 : 0
  vpc_id            = aws_vpc.metrics[0].id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.metrics[0].default_route_table_id]
  tags              = var.tags
}

resource "aws_vpc_endpoint" "metrics_logs" {
  count               = var.enable_vpc ? 1 : 0
  vpc_id              = aws_vpc.metrics[0].id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.metrics[*].id
  security_group_ids  = [aws_security_group.metrics_lambda[0].id]
  private_dns_enabled = true
  tags                = var.tags
}

# ---------------------------------------------------------------------------
# DynamoDB — raw metric events (PAY_PER_REQUEST: free-tier friendly at low traffic)
# ---------------------------------------------------------------------------
resource "aws_dynamodb_table" "metrics" {
  name = "${local.name_prefix}-metrics"
  # checkov:skip=CKV_AWS_119:Default AWS-managed KMS encryption suffices — raw events hold no PII (privacy-first beacon)
  # checkov:skip=CKV_AWS_28:Point-in-time recovery not needed — raw events are ephemeral (90-day TTL by design)
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "date"
  range_key    = "sk"

  attribute {
    name = "date"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }
  # GSI: page + date for per-page read queries (used by /summary with a filter,
  # reserved for the read-optimized follow-up).
  attribute {
    name = "page"
    type = "S"
  }
  global_secondary_index {
    name            = "page-date-index"
    hash_key        = "page"
    range_key       = "date"
    projection_type = "ALL"
  }

  ttl {
    enabled        = true
    attribute_name = "ttl"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Lambda — split by responsibility with least privilege:
#   writer (POST /event)  → dynamodb:PutItem only
#   reader (GET /summary · GET /views · GET /health) → dynamodb:Scan + Query
# ---------------------------------------------------------------------------
# The lambda source lives at <root>/lambda (shared, one zip per stack).
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.root}/lambda"
  output_path = "${path.root}/lambda.zip"
}

resource "aws_iam_role" "lambda_writer" {
  name = "${local.name_prefix}-metrics-writer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_writer_basic_execution" {
  role       = aws_iam_role.lambda_writer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_writer_dynamodb" {
  name = "metrics-writer-dynamodb"
  role = aws_iam_role.lambda_writer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem"]
      Resource = aws_dynamodb_table.metrics.arn
    }]
  })
}

resource "aws_lambda_function" "metrics_writer" {
  function_name    = "${local.name_prefix}-metrics-writer"
  role             = aws_iam_role.lambda_writer.arn
  handler          = "metrics_writer.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 10
  memory_size      = 128
  # checkov:skip=CKV_AWS_272:No code-signing pipeline — code ships from this repo (CI-built zip)
  # checkov:skip=CKV_AWS_116:DLQ applies to async invocations; API Gateway invokes synchronously
  # checkov:skip=CKV_AWS_173:Env vars encrypted at rest by Lambda's default AWS-managed key (free tier)
  # Reserved concurrency caps a public unauthenticated endpoint — cost guard (free).
  reserved_concurrent_executions = 2

  environment {
    variables = {
      TABLE_NAME      = aws_dynamodb_table.metrics.name
      EVENT_RETENTION = var.event_retention_days
      ALLOWED_ORIGIN  = join(",", local.metrics_origins)
    }
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = aws_subnet.metrics[*].id
      security_group_ids = [aws_security_group.metrics_lambda[0].id]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_writer_vpc_access" {
  count      = var.enable_vpc ? 1 : 0
  role       = aws_iam_role.lambda_writer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "lambda_reader" {
  name = "${local.name_prefix}-metrics-reader-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_reader_basic_execution" {
  role       = aws_iam_role.lambda_reader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_reader_dynamodb" {
  name = "metrics-reader-dynamodb"
  role = aws_iam_role.lambda_reader.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:Scan", "dynamodb:Query"]
      Resource = [
        aws_dynamodb_table.metrics.arn,
        "${aws_dynamodb_table.metrics.arn}/index/*",
      ]
    }]
  })
}

resource "aws_lambda_function" "metrics_reader" {
  function_name    = "${local.name_prefix}-metrics-reader"
  role             = aws_iam_role.lambda_reader.arn
  handler          = "metrics_reader.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 10
  memory_size      = 128
  # checkov:skip=CKV_AWS_272:No code-signing pipeline — code ships from this repo (CI-built zip)
  # checkov:skip=CKV_AWS_116:DLQ applies to async invocations; API Gateway invokes synchronously
  # checkov:skip=CKV_AWS_173:Env vars encrypted at rest by Lambda's default AWS-managed key (free tier)
  # Reserved concurrency caps a public unauthenticated endpoint — cost guard (free).
  reserved_concurrent_executions = 2

  environment {
    variables = {
      TABLE_NAME     = aws_dynamodb_table.metrics.name
      ALLOWED_ORIGIN = join(",", local.metrics_origins)
    }
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = aws_subnet.metrics[*].id
      security_group_ids = [aws_security_group.metrics_lambda[0].id]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_reader_vpc_access" {
  count      = var.enable_vpc ? 1 : 0
  role       = aws_iam_role.lambda_reader.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ---------------------------------------------------------------------------
# API Gateway (HTTP API) — /event (POST), /summary (GET), /health (GET)
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "metrics" {
  name          = "${local.name_prefix}-metrics-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = local.metrics_origins
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "X-Metrics-Type"]
    max_age       = 3600
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.metrics.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "write" {
  api_id                 = aws_apigatewayv2_api.metrics.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.metrics_writer.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "read" {
  api_id                 = aws_apigatewayv2_api.metrics.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.metrics_reader.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "post_event" {
  api_id    = aws_apigatewayv2_api.metrics.id
  route_key = "POST /event"
  target    = "integrations/${aws_apigatewayv2_integration.write.id}"
}

resource "aws_apigatewayv2_route" "get_summary" {
  api_id    = aws_apigatewayv2_api.metrics.id
  route_key = "GET /summary"
  target    = "integrations/${aws_apigatewayv2_integration.read.id}"
}

resource "aws_apigatewayv2_route" "get_health" {
  api_id    = aws_apigatewayv2_api.metrics.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.read.id}"
}

resource "aws_apigatewayv2_route" "get_views" {
  api_id    = aws_apigatewayv2_api.metrics.id
  route_key = "GET /views"
  target    = "integrations/${aws_apigatewayv2_integration.read.id}"
}

resource "aws_lambda_permission" "apigw_writer" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics_writer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.metrics.execution_arn}/*"
}

resource "aws_lambda_permission" "apigw_reader" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.metrics_reader.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.metrics.execution_arn}/*"
}

# ---------------------------------------------------------------------------
# CloudFront — geo headers (country/city) + stable HTTPS edge in front of the API
# ---------------------------------------------------------------------------
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
  tags            = var.tags
  is_ipv6_enabled = true
  # checkov:skip=CKV_AWS_86:Access logging skipped for a low-traffic personal site (deliberate)
  # checkov:skip=CKV_AWS_374:Geo restriction deliberately none — the metrics edge is public by design
  # checkov:skip=CKV_AWS_310:Single S3 origin — no secondary for failover (personal site)
  # checkov:skip=CKV_AWS_68:WAF excluded — outside the Free Tier (user constraint)

  origin {
    domain_name = replace(aws_apigatewayv2_api.metrics.api_endpoint, "https://", "")
    origin_id   = "metrics-api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "metrics-api"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    # Managed policy: CachingDisabled (dynamic API — never cache)
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = aws_cloudfront_origin_request_policy.geo[0].id
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
}

# Localized 500 error pages
# ---------------------------------------------------------------------------
# Edge origin gate — FREE WAF-equivalent (CloudFront Function, $0): only
# requests whose Origin/Referer host matches the site pass; /health is exempt
# for uptime probes. Replaces the paid WAF ACL's main rule at the edge.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# WAF — only the site's Origin/Referer may reach the edge; everything else is
# blocked, plus an IP rate-limit rule. Real AWS only (Ministack has no WAF).
# ---------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "metrics" {
  count = var.enable_waf ? 1 : 0
  name  = "${local.name_prefix}-metrics-acl"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    name     = "allow-site-origin"
    priority = 1
    action {
      allow {}
    }
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header { name = "origin" }
            }
            positional_constraint = "CONTAINS"
            search_string         = try(local.allowed_hosts[0], "")
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header { name = "referer" }
            }
            positional_constraint = "CONTAINS"
            search_string         = try(local.allowed_hosts[0], "")
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-site-origin"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 300
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "metrics"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "metrics" {
  count        = var.enable_waf ? 1 : 0
  resource_arn = aws_cloudfront_distribution.metrics[0].arn
  web_acl_arn  = aws_wafv2_web_acl.metrics[0].arn
}
