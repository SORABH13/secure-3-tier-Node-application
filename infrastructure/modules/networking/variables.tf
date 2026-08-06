variable "name" {
  description = "Name prefix for the networking module resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "List of Availability Zones to place subnets into."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "List of CIDR blocks for private application subnets."
  type        = list(string)
}

variable "private_db_subnet_cidrs" {
  description = "List of CIDR blocks for private database subnets."
  type        = list(string)
}

variable "enable_dns_support" {
  description = "Enable DNS support for the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames for the VPC."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment label used for additional tagging."
  type        = string
  default     = ""
}

locals {
  subnet_count_equal = length(var.availability_zones) == length(var.public_subnet_cidrs) && length(var.availability_zones) == length(var.private_app_subnet_cidrs) && length(var.availability_zones) == length(var.private_db_subnet_cidrs)
}

validation {
  condition     = length(var.availability_zones) >= 2
  error_message = "At least two availability zones are required for a production-ready networking module."
}

validation {
  condition     = local.subnet_count_equal
  error_message = "availability_zones, public_subnet_cidrs, private_app_subnet_cidrs, and private_db_subnet_cidrs must all have the same length."
}
