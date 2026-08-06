output "vpc_id" {
  description = "VPC ID created by the networking module."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs from networking module."
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs from networking module."
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs from networking module."
  value       = module.networking.private_db_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID from networking module."
  value       = module.networking.nat_gateway_id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID from networking module."
  value       = module.networking.internet_gateway_id
}
