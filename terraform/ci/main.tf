# CI bootstrap — GitHub→AWS identity + per-env state backend.
#
# WARNING (bootstrap drift, 2026-08-28): this module is applied ONLY by
# scripts/bootstrap-aws.sh <staging|prod> with admin credentials. Changes to
# the policies/roles below reach AWS only when that script is re-run — so
# after ANY change to this file, re-run the bootstrap for BOTH environments.
# Prod's role policy once lagged one run behind (missing ProjectDynamoDB /
# dynamodb:* on project tables) and the prod apply failed on
# dynamodb:UpdateTimeToLive while staging was fine — same code, drifted IAM.
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  provider_arn = (
    var.manage_provider
    ? aws_iam_openid_connect_provider.github[0].arn
    : data.aws_iam_openid_connect_provider.github[0].arn
  )

  # Trust policy for the TERRAFORM role (ref-scoped per environment: main only
  # for staging auto-applies, v* tags for prod plan/apply).
  assume_role_policy_terraform = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" : [
            # GitHub's sub claim includes node IDs since 2025:
            #   repo:OWNER@<owner-id>/REPO@<repo-id>:ref:refs/<ref>
            # so each repo pattern wildcards both IDs with @*; ref_patterns
            # then scopes the ref (e.g. main only for staging, v* tags for prod).
            for pair in setproduct(var.repos, var.ref_patterns) :
            "repo:${replace(pair[0], "/", "@*/")}@*:${pair[1]}"
          ]
        }
      }
    }]
  })

  # Trust policy for the DEPLOY role. The deploy workflows fire via
  # workflow_run, which runs on the DEFAULT branch (main) even when triggered
  # by a tag's CI success — so the deploy role must trust refs/heads/main; the
  # tag-only intent is enforced by deploy.yml's own v*-branch gate (2026-08-28:
  # the prod deploy failed AssumeRole because it trusted refs/tags/v* only).
  assume_role_policy_deploy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" : [
            for pair in setproduct(var.repos, var.deploy_ref_patterns) :
            "repo:${replace(pair[0], "/", "@*/")}@*:${pair[1]}"
          ]
        }
      }
    }]
  })
}

# ---------------------------------------------------------------------------
# OIDC identity provider for GitHub Actions
# (account-global: created once by the first environment, reused by the rest)
# ---------------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "github" {
  count = var.manage_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # GitHub's OIDC signing certificate thumbprints (SHA-1 of the DER certs from
  # https://token.actions.githubusercontent.com/.well-known/jwks). GitHub rotates
  # these keys — keep the original AND the current ones; a stale list makes STS
  # deny the assume with "Not authorized to perform sts:AssumeRoleWithWebIdentity".
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # original GitHub OIDC key
    "ca435a638a8cfed6b89364e064e08460b91c6250", # current GitHub OIDC key
    "38e9b30b3a023a1b72309921a69a42fcc496c42c", # current GitHub OIDC key
    "4f3e9ad8c9a6f5eb3173006f4fa630e28f43dce9", # current GitHub OIDC key
  ]
}

data "aws_iam_openid_connect_provider" "github" {
  count = var.manage_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# ---------------------------------------------------------------------------
# Role — assumed by GitHub Actions (OIDC), scoped per repo
# ---------------------------------------------------------------------------
resource "aws_iam_role" "terraform" {
  name = var.role_name

  assume_role_policy = local.assume_role_policy_terraform
  tags               = var.tags
}

# Deploy role — content sync (S3) + invalidation ONLY. Least privilege: this
# role runs on every deploy; the wide terraform role never sees content writes.
resource "aws_iam_role" "deploy" {
  name = var.deploy_role_name

  assume_role_policy = local.assume_role_policy_deploy
  tags               = var.tags
}

# --- Policy: terraform plan/apply on the metrics stack ---------------------
# Read + write on the my-portfolio-* resources (scoped by name prefix). IAM is
# scoped to project roles/policies (+ PassRole to the lambda roles only);
# ec2:/apigateway:/cloudfront: stay broad because those APIs don't support
# resource-level IAM conditions (AWS limitation).
resource "aws_iam_policy" "metrics_terraform" {
  name        = "${var.name_prefix}-${var.environment}-metrics-terraform"
  description = "Allow GitHub Actions to plan/apply the ${var.name_prefix} metrics terraform stack."
  # checkov:skip=CKV_AWS_290:MetricsStack statement is broad because CloudFront/API GW/EC2 actions are not resource-scopable (AWS limitation)
  # checkov:skip=CKV_AWS_355:MetricsStack needs Resource '*' for CloudFront/API GW/EC2 actions; S3/DynamoDB/state/IAM are scoped in their own statements
  # checkov:skip=CKV_AWS_289:MetricsStack includes permission-granting actions (lambda:AddPermission, ec2:AuthorizeSecurityGroupIngress) — AWS limitation + OIDC CI-role-only
  # checkov:skip=CKV_AWS_286:MetricsStack's broad write surface is required to manage the stack; the role is assumable only by this repo's CI (OIDC)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "StateBackend"
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*",
        ]
      },
      {
        Sid    = "StateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.state_lock_table}"
      },
      {
        Sid    = "MetricsStack"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
          "dynamodb:UpdateTable", "dynamodb:ListTables", "dynamodb:TagResource",
          "dynamodb:UntagResource", "dynamodb:ListTagsOfResource",
          "dynamodb:DescribeContinuousBackups", "dynamodb:DescribeTimeToLive",
          "lambda:CreateFunction", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration",
          "lambda:DeleteFunction", "lambda:GetFunction", "lambda:GetFunctionConfiguration", "lambda:ListFunctions",
          "lambda:ListVersionsByFunction", "lambda:GetPolicy", "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:AddPermission", "lambda:RemovePermission", "lambda:TagResource", "lambda:UntagResource", "lambda:ListTags",
          "lambda:PutFunctionConcurrency", "lambda:DeleteFunctionConcurrency", "lambda:GetFunctionConcurrency",
          "apigateway:POST", "apigateway:GET", "apigateway:PATCH", "apigateway:DELETE",
          "apigateway:PUT", "apigateway:CreateApiKey", "apigateway:TagResource", "apigateway:UntagResource",
          "apigateway:GetTags",
          "cloudfront:CreateDistribution", "cloudfront:UpdateDistribution", "cloudfront:DeleteDistribution",
          "cloudfront:GetDistribution", "cloudfront:ListDistributions", "cloudfront:ListTagsForResource",
          "cloudfront:TagResource", "cloudfront:UntagResource",
          "cloudfront:CreateOriginAccessControl", "cloudfront:UpdateOriginAccessControl",
          "cloudfront:DeleteOriginAccessControl", "cloudfront:GetOriginAccessControl",
          "cloudfront:ListOriginAccessControls",
          "cloudfront:GetDistributionConfig",
          "cloudfront:CreateFunction", "cloudfront:UpdateFunction", "cloudfront:DeleteFunction",
          "cloudfront:GetFunction", "cloudfront:DescribeFunction", "cloudfront:ListFunctions",
          "cloudfront:PublishFunction",
          "cloudfront:CreateOriginRequestPolicy", "cloudfront:UpdateOriginRequestPolicy",
          "cloudfront:DeleteOriginRequestPolicy", "cloudfront:GetOriginRequestPolicy",
          "cloudfront:CreateResponseHeadersPolicy", "cloudfront:UpdateResponseHeadersPolicy",
          "cloudfront:DeleteResponseHeadersPolicy", "cloudfront:GetResponseHeadersPolicy",
          "cloudfront:ListResponseHeadersPolicies",
          "wafv2:CreateWebACL", "wafv2:UpdateWebACL", "wafv2:DeleteWebACL", "wafv2:GetWebACL",
          "wafv2:AssociateWebACL", "wafv2:DisassociateWebACL",
          "ec2:CreateVpc", "ec2:DeleteVpc", "ec2:CreateSubnet", "ec2:DeleteSubnet",
          "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup", "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateVpcEndpoint", "ec2:DeleteVpcEndpoint", "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcs", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups",
          "ec2:DescribePrefixLists", "ec2:DescribeAvailabilityZones", "ec2:DescribeRouteTables",
          "ec2:CreateTags", "ec2:DeleteTags",
          "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup", "logs:TagResource", "logs:UntagResource",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "ProjectS3"
        Effect = "Allow"
        # All S3 on the PROJECT buckets only (state + site). s3:* avoids the
        # provider's ever-growing read set (ACL/tagging/versioning/policy ...)
        # while staying scoped to this project's buckets.
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*",
          "arn:aws:s3:::${var.site_bucket_prefix}*",
          "arn:aws:s3:::${var.site_bucket_prefix}*/*",
        ]
      },
      {
        Sid    = "ProjectDynamoDB"
        Effect = "Allow"
        # All DynamoDB on the PROJECT tables only (metrics + any future).
        # dynamodb:* avoids the provider's growing read set (TTL, contributor
        # insights, replica autoscaling, streams ...) while staying scoped.
        Action = ["dynamodb:*"]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.name_prefix}-*",
          "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.name_prefix}-*/index/*",
        ]
      },
      {
        Sid    = "IAMManage"
        Effect = "Allow"
        # Role + inline-policy management on THIS project's roles only (the
        # metrics lambda roles the stack creates). GetRole is restrictable, so
        # it's scoped too.
        Action = [
          "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
          "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
          "iam:ListRolePolicies", "iam:ListAttachedRolePolicies", "iam:UpdateAssumeRolePolicy",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:TagRole", "iam:UntagRole"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*"
      },
      {
        Sid    = "IAMList"
        Effect = "Allow"
        # Read-only list actions — not resource-restrictable (IAM API limitation).
        Action   = ["iam:ListRoles", "iam:ListPolicies"]
        Resource = "*"
      },
      {
        Sid    = "IAMPolicy"
        Effect = "Allow"
        Action = ["iam:CreatePolicy", "iam:DeletePolicy", "iam:GetPolicy"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.name_prefix}-*",
          "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
        ]
      },
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-${var.environment}-metrics-writer-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-${var.environment}-metrics-reader-role",
        ]
        Condition = {
          StringEquals = { "iam:PassedToService" = "lambda.amazonaws.com" }
        }
      },
    ]
  })
}

# --- Policy: future S3 site deploy (gh-pages → S3 + CloudFront invalidation)
resource "aws_iam_policy" "site_deploy" {
  name        = "${var.name_prefix}-${var.environment}-site-deploy"
  description = "Allow GitHub Actions to publish the site to S3 and invalidate CloudFront."
  # checkov:skip=CKV_AWS_355:CloudFront invalidation actions require Resource '*' (AWS API limitation); S3 actions are bucket-scoped
  # checkov:skip=CKV_AWS_290:cloudfront:CreateInvalidation on '*' is required — invalidation actions are not resource-scopable (AWS limitation)
  # checkov:skip=CKV_AWS_289:s3:PutBucketPolicy is permission management by design — the deploy role writes the site bucket policy

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SiteBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject", "s3:DeleteObject", "s3:ListBucket",
          "s3:GetBucketLocation", "s3:PutBucketPolicy"
        ]
        Resource = [
          "arn:aws:s3:::${var.site_bucket_prefix}*",
          "arn:aws:s3:::${var.site_bucket_prefix}*/*",
        ]
      },
      {
        Sid    = "Invalidate"
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation", "cloudfront:GetDistribution",
          "cloudfront:GetInvalidation", "cloudfront:ListDistributions",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "metrics_terraform" {
  role       = aws_iam_role.terraform.name
  policy_arn = aws_iam_policy.metrics_terraform.arn
}

resource "aws_iam_role_policy_attachment" "site_deploy" {
  role       = aws_iam_role.deploy.name
  policy_arn = aws_iam_policy.site_deploy.arn
}

# ---------------------------------------------------------------------------
# Terraform state backend (S3 bucket + DynamoDB lock) — used by the metrics
# stack's versions.tf and by CI, so every plan/apply shares one state.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket
  tags   = var.tags
  # checkov:skip=CKV_AWS_144:Cross-region replication = extra cost — single-region personal site (free tier)
  # checkov:skip=CKV2_AWS_62:No S3 event consumers — nothing triggers on bucket events
  # checkov:skip=CKV_AWS_18:Access logging skipped — low-traffic personal site (deliberate)
  # checkov:skip=CKV2_AWS_61:No lifecycle — state versions kept indefinitely for recovery
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      # aws:kms with the AWS-managed key (alias/aws/s3) — KMS encryption at zero cost.
      sse_algorithm     = "aws:kms"
      kms_master_key_id = "alias/aws/s3"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tfstate_lock" {
  name = var.state_lock_table
  # checkov:skip=CKV_AWS_119:Default AWS-managed KMS encryption is sufficient (lock table holds only lock tokens)
  # checkov:skip=CKV_AWS_28:Point-in-time recovery not needed for the state lock table (recreatable)
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
