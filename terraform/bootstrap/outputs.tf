output "role_arn" {
  description = "The GitHub Actions TERRAFORM role — put this in the repo's <ENV>_TERRAFORM_ROLE_ARN secret."
  value       = aws_iam_role.terraform.arn
}

output "deploy_role_arn" {
  description = "The GitHub Actions DEPLOY role — put this in the repo's <ENV>_DEPLOY_ROLE_ARN secret."
  value       = aws_iam_role.deploy.arn
}

output "oidc_provider_arn" {
  description = "The GitHub OIDC identity provider ARN."
  value = (
    var.manage_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )
}

output "state_bucket" {
  description = "S3 state bucket (backend for the metrics stack)."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_lock_table" {
  description = "DynamoDB state-lock table."
  value       = aws_dynamodb_table.tfstate_lock.name
}
