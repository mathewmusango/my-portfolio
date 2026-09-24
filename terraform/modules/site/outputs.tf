output "bucket_id" {
  description = "Private site bucket id (content is synced by the deploy workflow)."
  value       = var.enable_site ? aws_s3_bucket.site[0].id : null
}

output "distribution_id" {
  description = "CloudFront distribution serving the site — id for invalidation."
  value       = var.enable_site ? aws_cloudfront_distribution.site[0].id : null
}

output "distribution_domain_name" {
  description = "CloudFront domain name — allowed as a metrics origin when the site is enabled."
  value       = var.enable_site ? aws_cloudfront_distribution.site[0].domain_name : null
}

output "site_url" {
  description = "Public site URL (CloudFront edge)."
  value       = var.enable_site ? "https://${aws_cloudfront_distribution.site[0].domain_name}" : null
}
