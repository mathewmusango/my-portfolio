output "role_name" {
  description = "Role name."
  value       = aws_iam_role.this.name
}

output "role_arn" {
  description = "Role ARN."
  value       = aws_iam_role.this.arn
}
