output "vpc_id" {
  description = "VPC id."
  value       = var.enable ? aws_vpc.this[0].id : null
}

output "subnet_ids" {
  description = "Subnet ids."
  value       = var.enable ? aws_subnet.this[*].id : []
}

output "security_group_id" {
  description = "Security group id."
  value       = var.enable ? aws_security_group.this[0].id : null
}
