variable "name" {
  description = "Name prefix for the $module module."
  type        = string
}

variable "tags" {
  description = "Common tags for resources created by the $module module."
  type        = map(string)
  default     = {}
}
