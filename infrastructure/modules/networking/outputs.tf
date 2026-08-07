output "vpc_id" {
  description = "VPC ID created by the networking module."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs created for the VPC."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_app_subnet_ids" {
  description = "Private application subnet IDs created for the VPC."
  value       = [for subnet in aws_subnet.private_app : subnet.id]
}

output "private_db_subnet_ids" {
  description = "Private database subnet IDs created for the VPC."
  value       = [for subnet in aws_subnet.private_db : subnet.id]
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs, one per Availability Zone, for outbound traffic from private application subnets."
  value       = { for az, nat in aws_nat_gateway.this : az => nat.id }
}

output "internet_gateway_id" {
  description = "Internet Gateway ID attached to the VPC."
  value       = aws_internet_gateway.this.id
}
