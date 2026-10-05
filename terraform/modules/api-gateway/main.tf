resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors.allow_origins
    allow_methods = var.cors.allow_methods
    allow_headers = var.cors.allow_headers
    max_age       = var.cors.max_age
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
  # checkov:skip=CKV_AWS_76:Access logging skipped — free tier, low traffic; Lambda CloudWatch logs cover the path
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = var.integrations

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.value.integration_key].id}"
  # checkov:skip=CKV_AWS_309:Public beacon by design — auth is the edge origin-gate (403 non-site origins) + Lambda origin gate
}

resource "aws_lambda_permission" "this" {
  for_each = var.integrations

  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*"
}
