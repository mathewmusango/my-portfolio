locals {
  managed_policies = concat(
    ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"],
    var.enable_vpc ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"] : [],
  )
}

module "iam" {
  source              = "../iam"
  role_name           = var.role_name
  tags                = var.tags
  inline_policies     = var.iam_policies
  managed_policy_arns = local.managed_policies
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = module.iam.role_arn
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

moved {
  from = aws_iam_role.this
  to   = module.iam.aws_iam_role.this
}

moved {
  from = aws_iam_role_policy_attachment.basic_execution
  to   = module.iam.aws_iam_role_policy_attachment.managed["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

moved {
  from = aws_iam_role_policy_attachment.vpc_access[0]
  to   = module.iam.aws_iam_role_policy_attachment.managed["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
}

moved {
  from = aws_iam_policy.this
  to   = module.iam.aws_iam_policy.this
}

moved {
  from = aws_iam_role_policy_attachment.this
  to   = module.iam.aws_iam_role_policy_attachment.inline
}
