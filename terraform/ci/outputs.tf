output "role_arn" {
  description = "The GitHub Actions role — put this in the repo's AWS_ROLE_ARN variable."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "The GitHub OIDC identity provider ARN."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "state_bucket" {
  description = "S3 state bucket (backend for the metrics stack)."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_lock_table" {
  description = "DynamoDB state-lock table."
  value       = aws_dynamodb_table.tfstate_lock.name
}
