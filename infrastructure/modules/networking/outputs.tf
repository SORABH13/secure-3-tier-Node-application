output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.this.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for subnet in local.public_subnets : aws_subnet.public[subnet.name].id]
}

output "private_app_subnet_ids" {
  description = "List of private application subnet IDs."
  value       = [for subnet in local.private_app_subnets : aws_subnet.private_app[subnet.name].id]
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs."
  value       = [for subnet in local.private_db_subnets : aws_subnet.private_db[subnet.name].id]
}

output "nat_gateway_id" {
  description = "The ID of the NAT Gateway used by private application subnets."
  value       = aws_nat_gateway.this.id
}

output "nat_eip_allocation_id" {
  description = "The allocation ID for the NAT Gateway Elastic IP."
  value       = aws_eip.nat.id
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_app_route_table_id" {
  description = "The ID of the private application route table."
  value       = aws_route_table.private_app.id
}

output "private_db_route_table_id" {
  description = "The ID of the private database route table."
  value       = aws_route_table.private_db.id
}
