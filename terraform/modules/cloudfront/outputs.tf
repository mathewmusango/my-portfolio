output "distribution_id" {
  description = "CloudFront distribution id (invalidation target)."
  value       = var.enable ? aws_cloudfront_distribution.this[0].id : null
}

output "distribution_arn" {
  description = "CloudFront distribution ARN."
  value       = var.enable ? aws_cloudfront_distribution.this[0].arn : null
}

output "distribution_domain_name" {
  description = "CloudFront domain name."
  value       = var.enable ? aws_cloudfront_distribution.this[0].domain_name : null
}

output "url" {
  description = "Distribution URL."
  value       = var.enable ? "https://${aws_cloudfront_distribution.this[0].domain_name}" : null
}
