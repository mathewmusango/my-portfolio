output "table_name" {
  description = "Table name."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "Table ARN."
  value       = aws_dynamodb_table.this.arn
}
