output "bucket_id" {
  description = "Bucket id."
  value       = var.enable ? aws_s3_bucket.this[0].id : null
}

output "bucket_arn" {
  description = "Bucket ARN."
  value       = var.enable ? aws_s3_bucket.this[0].arn : null
}

output "bucket_regional_domain_name" {
  description = "Regional bucket domain name (CloudFront origin)."
  value       = var.enable ? aws_s3_bucket.this[0].bucket_regional_domain_name : null
}
