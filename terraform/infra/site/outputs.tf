output "bucket_id" {
  description = "Private site bucket id (content is synced by the deploy workflow)."
  value       = module.s3.bucket_id
}

output "distribution_id" {
  description = "CloudFront distribution serving the site — id for invalidation."
  value       = module.cloudfront.distribution_id
}

output "distribution_domain_name" {
  description = "CloudFront domain name — allowed as a metrics origin when the site is enabled."
  value       = module.cloudfront.distribution_domain_name
}

output "site_url" {
  description = "Public site URL (CloudFront edge)."
  value       = module.cloudfront.url
}
