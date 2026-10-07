data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_prefix_list" "interface" {
  for_each = var.enable ? var.interface_endpoints : tomap({})
  name     = each.value.service_name
}

resource "aws_vpc" "this" {
  count                = var.enable ? 1 : 0
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.tags
  # checkov:skip=CKV2_AWS_11:VPC flow logging costs — the VPC is count-gated OFF (enable_vpc=false, Free-Tier)
  # checkov:skip=CKV2_AWS_12:Default SG untouched — the VPC is count-gated OFF (enable_vpc=false, Free-Tier)
}

resource "aws_subnet" "this" {
  count             = var.enable ? var.subnet_count : 0
  vpc_id            = aws_vpc.this[0].id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags              = var.tags
}

resource "aws_security_group" "this" {
  count       = var.enable ? 1 : 0
  vpc_id      = aws_vpc.this[0].id
  name        = var.security_group_name
  description = "Egress to interface endpoints only"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  dynamic "egress" {
    for_each = length(var.interface_endpoints) > 0 ? [1] : []
    content {
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = [for pl in data.aws_prefix_list.interface : pl.id]
    }
  }

  tags = var.tags
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.enable ? var.gateway_endpoints : tomap({})

  vpc_id            = aws_vpc.this[0].id
  service_name      = each.value
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.this[0].default_route_table_id]
  tags              = var.tags
}

resource "aws_vpc_endpoint" "interface" {
  for_each = var.enable ? var.interface_endpoints : tomap({})

  vpc_id              = aws_vpc.this[0].id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.this[*].id
  security_group_ids  = [aws_security_group.this[0].id]
  private_dns_enabled = each.value.private_dns_enabled
  tags                = var.tags
}
