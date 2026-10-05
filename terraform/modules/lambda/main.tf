resource "aws_iam_role" "this" {
  name = var.role_name

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

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "this" {
  for_each = var.iam_policies

  name   = each.value.name
  policy = each.value.policy
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.iam_policies

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  runtime          = var.runtime
  filename         = var.filename
  source_code_hash = var.source_code_hash
  timeout          = var.timeout
  memory_size      = var.memory_size
  # checkov:skip=CKV_AWS_272:No code-signing pipeline — code ships from this repo (CI-built zip)
  # checkov:skip=CKV_AWS_116:DLQ applies to async invocations; API Gateway invokes synchronously
  # checkov:skip=CKV_AWS_173:Env vars encrypted at rest by Lambda's default AWS-managed key (free tier)
  # checkov:skip=CKV_AWS_50:Observability via CloudWatch logs + the site's own metrics; X-Ray out (marginal value)
  # checkov:skip=CKV_AWS_115:Account Lambda concurrency limit is 10 — the unreserved minimum is 10, so reserved concurrency is impossible without a quota increase; the endpoint is origin-gated (403 non-site origins)

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [var.environment] : []
    content {
      variables = environment.value
    }
  }

  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = var.enable_vpc ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
