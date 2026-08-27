output "api_url" {
  description = "Public metrics endpoint (CloudFront edge in front of API Gateway; falls back to the API Gateway URL when CloudFront is disabled)."
  value       = var.enable_cloudfront ? "https://${aws_cloudfront_distribution.metrics[0].domain_name}" : aws_apigatewayv2_api.metrics.api_endpoint
}

output "api_gateway_url" {
  description = "Direct API Gateway invoke URL (bypasses CloudFront — no geo headers)."
  value       = aws_apigatewayv2_api.metrics.api_endpoint
}

output "table_name" {
  description = "DynamoDB table holding raw metric events."
  value       = aws_dynamodb_table.metrics.name
}

output "lambda_writer_function_name" {
  description = "Metrics writer Lambda (POST /event, dynamodb:PutItem only)."
  value       = aws_lambda_function.metrics_writer.function_name
}

output "lambda_reader_function_name" {
  description = "Metrics reader Lambda (GET /summary · /health, dynamodb:Scan only)."
  value       = aws_lambda_function.metrics_reader.function_name
}

output "event_endpoint" {
  description = "POST target for the site beacon: {api_url}/event"
  value       = "${var.enable_cloudfront ? "https://${aws_cloudfront_distribution.metrics[0].domain_name}" : aws_apigatewayv2_api.metrics.api_endpoint}/event"
}

output "summary_endpoint" {
  description = "Aggregate reader: {api_url}/summary"
  value       = "${var.enable_cloudfront ? "https://${aws_cloudfront_distribution.metrics[0].domain_name}" : aws_apigatewayv2_api.metrics.api_endpoint}/summary"
}

output "health_endpoint" {
  description = "Uptime probe target: {api_url}/health"
  value       = "${var.enable_cloudfront ? "https://${aws_cloudfront_distribution.metrics[0].domain_name}" : aws_apigatewayv2_api.metrics.api_endpoint}/health"
}
