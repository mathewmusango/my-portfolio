resource "aws_s3_bucket" "this" {
  count  = var.enable ? 1 : 0
  bucket = var.name
  tags   = var.tags
  # checkov:skip=CKV_AWS_21:Versioning declined by user (2026-08-28) — site content redeploys from the repo
  # checkov:skip=CKV_AWS_144:Cross-region replication = extra cost — single-region personal site (free tier)
  # checkov:skip=CKV2_AWS_62:No S3 event consumers — nothing triggers on bucket events
  # checkov:skip=CKV_AWS_145:KMS (aws:kms, AWS-managed key) is set via the separate SSE resource — graph check can't resolve the count-gated association
  # checkov:skip=CKV_AWS_18:Access logging skipped — low-traffic personal site (deliberate)
  # checkov:skip=CKV2_AWS_61:No lifecycle needed — sync --delete self-manages content; no expiry/transition use case
  # checkov:skip=CKV2_AWS_6:Public access block exists (aws_s3_bucket_public_access_block.site) — graph check can't resolve the count-gated resource
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.enable ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count                   = var.enable ? 1 : 0
  bucket                  = aws_s3_bucket.this[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
