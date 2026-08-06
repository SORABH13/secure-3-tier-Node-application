# Networking Module

This Terraform module creates a production-ready AWS networking foundation for ECS Fargate deployments.

## Architecture

The module provisions a single VPC with a multi-AZ subnet architecture:

- 1 VPC
- 1 Internet Gateway
- 2 public subnets across two Availability Zones
- 2 private application subnets across two Availability Zones
- 2 private database subnets across two Availability Zones
- 1 Elastic IP for the NAT Gateway
- 1 NAT Gateway
- 1 public route table
- 1 private application route table
- 1 private database route table
- Route table associations for every subnet

### Design notes

- Public subnets allow inbound access for load balancers and NAT gateway placement.
- Private application subnets use a NAT Gateway for outbound internet access.
- Private database subnets are isolated and do not route traffic to the internet.
- CIDR blocks and Availability Zones are fully configurable.
- All resources are tagged for observability and lifecycle management.

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  name                    = "secure-3-tier"
  vpc_cidr                = "10.0.0.0/16"
  availability_zones      = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_app_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
  private_db_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24"]
  tags = {
    Project     = "secure-3-tier-node-application"
    Environment = "prod"
  }
}
```

## Variables

- `name`: Prefix used for resource names.
- `vpc_cidr`: VPC CIDR block.
- `availability_zones`: One AZ per subnet pair. At least two are required.
- `public_subnet_cidrs`: CIDRs for public subnets.
- `private_app_subnet_cidrs`: CIDRs for private application subnets.
- `private_db_subnet_cidrs`: CIDRs for private database subnets.
- `enable_dns_support`: Toggle VPC DNS support.
- `enable_dns_hostnames`: Toggle DNS hostnames in the VPC.
- `tags`: Common tags applied to all resources.

## Outputs

- `vpc_id`
- `internet_gateway_id`
- `public_subnet_ids`
- `private_app_subnet_ids`
- `private_db_subnet_ids`
- `nat_gateway_id`
- `nat_eip_allocation_id`
- `public_route_table_id`
- `private_app_route_table_id`
- `private_db_route_table_id`

## Best practices

- Keep private database subnets isolated from the internet.
- Use the private application subnets for ECS tasks that require outbound access.
- Extend this module with additional NAT Gateway redundancy if you need AZ-level egress resilience.
