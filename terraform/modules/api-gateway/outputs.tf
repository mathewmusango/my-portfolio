output "api_id" {
  description = "HTTP API id."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "Direct API Gateway invoke URL."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "execution_arn" {
  description = "API execution ARN (Lambda permission source)."
  value       = aws_apigatewayv2_api.this.execution_arn
}
