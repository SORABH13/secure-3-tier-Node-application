variable "project_name" {
  description = "Project name used for CloudFront distribution naming and tagging."
  type        = string
}

variable "environment" {
  description = "Environment used for CloudFront distribution naming and tagging."
  type        = string
}

variable "origin_domain_name" {
  description = "Origin domain name for the CloudFront distribution."
  type        = string
}

variable "origin_path" {
  description = "Origin path prefix for CloudFront."
  type        = string
  default     = ""
}

variable "aliases" {
  description = "Optional CNAME aliases for the distribution."
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN for CloudFront HTTPS."
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Additional tags applied to CloudFront resources."
  type        = map(string)
  default     = {}
}
