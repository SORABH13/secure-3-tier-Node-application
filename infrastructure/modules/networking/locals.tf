locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  public_subnets = [for idx, az in var.availability_zones : {
    name = format("%s-public-%02d", local.name_prefix, idx + 1)
    az   = az
    cidr = var.public_subnet_cidrs[idx]
  }]

  private_app_subnets = [for idx, az in var.availability_zones : {
    name = format("%s-private-app-%02d", local.name_prefix, idx + 1)
    az   = az
    cidr = var.private_app_subnet_cidrs[idx]
  }]

  private_db_subnets = [for idx, az in var.availability_zones : {
    name = format("%s-private-db-%02d", local.name_prefix, idx + 1)
    az   = az
    cidr = var.private_db_subnet_cidrs[idx]
  }]
}
