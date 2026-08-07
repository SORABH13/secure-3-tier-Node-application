resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(local.common_tags, {
    Name = format("%s-vpc%s", local.name_prefix, length(trimspace(var.name_suffix)) > 0 ? "-" : "")
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = format("%s-igw", local.name_prefix)
  })
}

# One NAT Gateway per AZ so a single AZ failure cannot take down outbound
# internet access (ECR pulls, Secrets Manager calls) for every private subnet.
resource "aws_eip" "nat" {
  for_each = { for subnet in local.public_subnets : subnet.az => subnet }

  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = merge(local.common_tags, {
    Name = format("%s-nat-eip-%s", local.name_prefix, each.key)
  })
}

resource "aws_nat_gateway" "this" {
  for_each = { for subnet in local.public_subnets : subnet.az => subnet }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.value.name].id

  tags = merge(local.common_tags, {
    Name = format("%s-nat-gateway-%s", local.name_prefix, each.key)
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public" {
  for_each = { for subnet in local.public_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name       = each.value.name
    SubnetTier = "public"
  })
}

resource "aws_subnet" "private_app" {
  for_each = { for subnet in local.private_app_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name       = each.value.name
    SubnetTier = "private_app"
  })
}

resource "aws_subnet" "private_db" {
  for_each = { for subnet in local.private_db_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name       = each.value.name
    SubnetTier = "private_db"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = format("%s-public-rt", local.name_prefix)
  })
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table" "private_app" {
  for_each = { for subnet in local.public_subnets : subnet.az => subnet }

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = format("%s-private-app-rt-%s", local.name_prefix, each.key)
  })
}

resource "aws_route" "private_app_nat" {
  for_each = aws_route_table.private_app

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = format("%s-private-db-rt", local.name_prefix)
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.value.availability_zone].id
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db.id
}
