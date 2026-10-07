variable "name" {
  description = "Table name."
  type        = string
}

variable "tags" {
  description = "Tags applied to the table."
  type        = map(string)
}

variable "billing_mode" {
  description = "DynamoDB billing mode."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "Partition key attribute name."
  type        = string
}

variable "range_key" {
  description = "Sort key attribute name."
  type        = string
  default     = null
}

variable "attributes" {
  description = "Key attributes referenced by the table and its indexes."
  type = list(object({
    name = string
    type = string
  }))
}

variable "global_secondary_indexes" {
  description = "Global secondary indexes."
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = string
    projection_type = string
  }))
  default = []
}

variable "ttl_attribute" {
  description = "Attribute holding the expiry timestamp; TTL is enabled when set."
  type        = string
  default     = null
}

variable "point_in_time_recovery" {
  description = "Enable point-in-time recovery."
  type        = bool
  default     = false
}
