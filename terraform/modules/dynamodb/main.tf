resource "aws_dynamodb_table" "this" {
  name         = var.name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key
  # checkov:skip=CKV_AWS_119:Default AWS-managed KMS encryption suffices — raw events hold no PII (privacy-first beacon)
  # checkov:skip=CKV_AWS_28:Point-in-time recovery not needed — raw events are ephemeral (90-day TTL by design)

  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute == null ? [] : [var.ttl_attribute]
    content {
      enabled        = true
      attribute_name = ttl.value
    }
  }

  dynamic "point_in_time_recovery" {
    for_each = var.point_in_time_recovery ? [1] : []
    content {
      enabled = true
    }
  }

  tags = var.tags
}
