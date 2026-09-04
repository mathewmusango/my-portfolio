# --- Site ---
output "site_bucket" {
  description = "Private site bucket (content synced by the deploy workflow)."
  value       = var.enable_site ? aws_s3_bucket.site[0].id : null
}

output "site_distribution_id" {
  description = "CloudFront distribution serving the site — id for invalidation."
  value       = var.enable_site ? aws_cloudfront_distribution.site[0].id : null
}

output "site_url" {
  description = "Public site URL (CloudFront edge)."
  value       = var.enable_site ? "https://${aws_cloudfront_distribution.site[0].domain_name}" : null
}

# --- Metrics (only when enable_metrics) ---
output "api_url" {
  description = "Public metrics endpoint (CloudFront edge in front of API Gateway)."
  value       = var.enable_metrics ? module.metrics[0].api_url : null
}

output "api_gateway_url" {
  description = "Direct API Gateway invoke URL (bypasses CloudFront — no geo headers)."
  value       = var.enable_metrics ? module.metrics[0].api_gateway_url : null
}

output "table_name" {
  description = "DynamoDB table holding raw metric events."
  value       = var.enable_metrics ? module.metrics[0].table_name : null
}

output "lambda_writer_function_name" {
  description = "Metrics writer Lambda (POST /event, dynamodb:PutItem only)."
  value       = var.enable_metrics ? module.metrics[0].lambda_writer_function_name : null
}

output "lambda_reader_function_name" {
  description = "Metrics reader Lambda (GET /summary · /views · /health, dynamodb:Scan + Query on table + GSI)."
  value       = var.enable_metrics ? module.metrics[0].lambda_reader_function_name : null
}

output "event_endpoint" {
  description = "POST target for the site beacon: {api_url}/event"
  value       = var.enable_metrics ? module.metrics[0].event_endpoint : null
}

output "summary_endpoint" {
  description = "Aggregate reader: {api_url}/summary"
  value       = var.enable_metrics ? module.metrics[0].summary_endpoint : null
}

output "health_endpoint" {
  description = "Uptime probe target: {api_url}/health"
  value       = var.enable_metrics ? module.metrics[0].health_endpoint : null
}
