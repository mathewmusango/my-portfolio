variable "name" {
  description = "Bucket name."
  type        = string
}

variable "tags" {
  description = "Tags applied to the bucket."
  type        = map(string)
}

variable "enable" {
  description = "Create the bucket and its companion resources."
  type        = bool
}
