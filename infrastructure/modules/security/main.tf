resource "aws_security_group" "alb" {
  name        = format("%s-alb", local.name_prefix)
  description = "Application Load Balancer security group."
  vpc_id      = var.vpc_id

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr -- this is the public entry
  # point of a 3-tier app that's explicitly required to be internet-facing
  # (Web tier must be publicly accessible). Everything behind it (web SG,
  # api SG, postgres SG) is private and NOT internet-reachable.
  ingress {
    description      = "Allow HTTP traffic from public internet CIDRs."
    from_port        = var.alb_http_port
    to_port          = var.alb_http_port
    protocol         = "tcp"
    cidr_blocks      = var.alb_ingress_cidrs
    ipv6_cidr_blocks = var.alb_ingress_ipv6_cidrs
  }

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr -- see above.
  ingress {
    description      = "Allow HTTPS traffic from public internet CIDRs."
    from_port        = var.alb_https_port
    to_port          = var.alb_https_port
    protocol         = "tcp"
    cidr_blocks      = var.alb_ingress_cidrs
    ipv6_cidr_blocks = var.alb_ingress_ipv6_cidrs
  }

  tags = merge(local.common_tags, {
    Name = format("%s-alb", local.name_prefix)
  })
}

resource "aws_security_group" "web" {
  name        = format("%s-web", local.name_prefix)
  description = "Web ECS service security group."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = format("%s-web", local.name_prefix)
  })
}

resource "aws_security_group" "api" {
  name        = format("%s-api", local.name_prefix)
  description = "API ECS service security group."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = format("%s-api", local.name_prefix)
  })
}

# description is intentionally left exactly as originally created --
# aws_security_group.description is immutable (ForceNew): editing it would
# force-replace this SG on next apply, detaching it from the live RDS
# instance. (No egress rule below is deliberate: RDS never initiates
# outbound connections, so none is needed.)
resource "aws_security_group" "postgres" {
  name        = format("%s-postgres", local.name_prefix)
  description = "PostgreSQL RDS security group. Only API ECS traffic is permitted."
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = format("%s-postgres", local.name_prefix)
  })
}

# --- Ingress: every hop is scoped to the specific SG allowed to call it ---

resource "aws_security_group_rule" "web_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.web_service_port
  to_port                  = var.web_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow traffic from ALB to Web ECS."
}

resource "aws_security_group_rule" "api_ingress_from_web" {
  type                     = "ingress"
  from_port                = var.api_service_port
  to_port                  = var.api_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api.id
  source_security_group_id = aws_security_group.web.id
  description              = "Allow traffic from Web ECS to API ECS."
}

resource "aws_security_group_rule" "postgres_ingress_from_api" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.postgres.id
  source_security_group_id = aws_security_group.api.id
  description              = "Allow PostgreSQL traffic from API ECS."
}

# --- Egress: least privilege. Only the ALB->web hop, web->api hop, and
# api->postgres hop are SG-to-SG (no public CIDR involved at all). Web and
# API also need 443 to the internet (via NAT) for ECR pulls, Secrets
# Manager, and CloudWatch Logs API calls -- there are no VPC interface
# endpoints for those services in this design, which is the one remaining,
# documented tradeoff. Postgres gets no egress rule at all. ---

resource "aws_security_group_rule" "alb_egress_to_web" {
  type                     = "egress"
  from_port                = var.web_service_port
  to_port                  = var.web_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.web.id
  description              = "Allow the ALB to reach Web ECS targets only."
}

resource "aws_security_group_rule" "web_egress_to_api" {
  type                     = "egress"
  from_port                = var.api_service_port
  to_port                  = var.api_service_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web.id
  source_security_group_id = aws_security_group.api.id
  description              = "Allow Web ECS to call the API tier."
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr -- Web ECS has no VPC interface
# endpoints for ECR/Secrets Manager/CloudWatch Logs, so it must reach them
# over the internet (via the NAT Gateway) on 443. Adding those endpoints
# would remove this rule entirely; documented as a follow-up in the runbook.
resource "aws_security_group_rule" "web_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.web.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Web ECS to reach ECR/Secrets Manager/CloudWatch over HTTPS via the NAT Gateway."
}

resource "aws_security_group_rule" "api_egress_to_postgres" {
  type                     = "egress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api.id
  source_security_group_id = aws_security_group.postgres.id
  description              = "Allow API ECS to reach RDS PostgreSQL."
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr -- same rationale as web_egress_https.
resource "aws_security_group_rule" "api_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.api.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow API ECS to reach ECR/Secrets Manager/CloudWatch over HTTPS via the NAT Gateway."
}
