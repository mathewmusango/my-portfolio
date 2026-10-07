output "web_acl_arn" {
  description = "Web ACL ARN."
  value       = var.enable ? aws_wafv2_web_acl.this[0].arn : null
}
