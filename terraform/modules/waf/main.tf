resource "aws_wafv2_web_acl" "this" {
  count = var.enable ? 1 : 0
  name  = var.name
  scope = var.scope
  # checkov:skip=CKV2_AWS_31:WAF excluded from the Free-Tier constraint — resource is count-gated off (not deployed)

  default_action {
    block {}
  }

  rule {
    name     = "allow-host"
    priority = 1
    action {
      allow {}
    }
    statement {
      or_statement {
        statement {
          byte_match_statement {
            field_to_match {
              single_header { name = "origin" }
            }
            positional_constraint = "CONTAINS"
            search_string         = var.allowed_host
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
        statement {
          byte_match_statement {
            field_to_match {
              single_header { name = "referer" }
            }
            positional_constraint = "CONTAINS"
            search_string         = var.allowed_host
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-host"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "rate-limit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit"
      sampled_requests_enabled   = true
    }
  }

  tags = var.tags
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.metric_name
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable ? 1 : 0
  resource_arn = var.association_arn
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
}
