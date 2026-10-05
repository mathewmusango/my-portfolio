variable "security_group_name" {
  description = "Name of the security group shared by the endpoints and their consumers."
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}

variable "enable" {
  description = "Create the VPC, its subnets, security group and endpoints."
  type        = bool
}

variable "cidr_block" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of /24 subnets to carve from the CIDR, one per availability zone."
  type        = number
  default     = 2
}

variable "gateway_endpoints" {
  description = "Gateway endpoints to create, keyed by a stable name (value is the service name)."
  type        = map(string)
  default     = {}
}

variable "interface_endpoints" {
  description = "Interface endpoints to create, keyed by a stable name."
  type = map(object({
    service_name        = string
    private_dns_enabled = bool
  }))
  default = {}
}
