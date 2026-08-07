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

# map_public_ip_on_launch is off even here: nothing is ever launched directly
# into these subnets with an auto-assigned public IP (the ALB and NAT
# Gateways get their public-facing addresses via their own ENIs/EIPs, not
# this setting). Leaving it off is a free defense-in-depth measure against
# something being placed here by accident later.
resource "aws_subnet" "public" {
  for_each = { for subnet in local.public_subnets : subnet.name => subnet }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

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

# --- VPC Flow Logs: network-level audit trail, complements CloudTrail
# (API-level audit) and the application CloudWatch Logs. ---

resource "aws_cloudwatch_log_group" "flow_log" {
  name              = format("/vpc/%s-flow-log", local.name_prefix)
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  tags = merge(local.common_tags, {
    Name = format("%s-flow-log", local.name_prefix)
  })
}

data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log" {
  name               = format("%s-flow-log-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "flow_log_publish" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = [format("%s:*", aws_cloudwatch_log_group.flow_log.arn)]
  }
}

resource "aws_iam_role_policy" "flow_log_publish" {
  name   = format("%s-flow-log-publish", local.name_prefix)
  role   = aws_iam_role.flow_log.id
  policy = data.aws_iam_policy_document.flow_log_publish.json
}

resource "aws_flow_log" "this" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_log.arn
  iam_role_arn         = aws_iam_role.flow_log.arn

  tags = merge(local.common_tags, {
    Name = format("%s-flow-log", local.name_prefix)
  })
}
