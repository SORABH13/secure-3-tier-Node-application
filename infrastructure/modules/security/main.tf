resource "aws_security_group" "alb" {
  name        = format("%s-alb", local.name_prefix)
  description = "Application Load Balancer security group."
  vpc_id      = var.vpc_id

  ingress {
    description      = "Allow HTTP traffic from public internet CIDRs."
    from_port        = var.alb_http_port
    to_port          = var.alb_http_port
    protocol         = "tcp"
    cidr_blocks      = var.alb_ingress_cidrs
    ipv6_cidr_blocks = var.alb_ingress_ipv6_cidrs
  }

  ingress {
    description      = "Allow HTTPS traffic from public internet CIDRs."
    from_port        = var.alb_https_port
    to_port          = var.alb_https_port
    protocol         = "tcp"
    cidr_blocks      = var.alb_ingress_cidrs
    ipv6_cidr_blocks = var.alb_ingress_ipv6_cidrs
  }

  egress {
    description      = "Allow outbound traffic from the ALB to targets and health checks."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-alb", local.name_prefix)
  })
}

resource "aws_security_group" "web" {
  name        = format("%s-web", local.name_prefix)
  description = "Web ECS service security group."
  vpc_id      = var.vpc_id

  egress {
    description      = "Allow outbound traffic from Web ECS."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-web", local.name_prefix)
  })
}

resource "aws_security_group" "api" {
  name        = format("%s-api", local.name_prefix)
  description = "API ECS service security group."
  vpc_id      = var.vpc_id

  egress {
    description      = "Allow outbound traffic from API ECS."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-api", local.name_prefix)
  })
}

resource "aws_security_group" "postgres" {
  name        = format("%s-postgres", local.name_prefix)
  description = "PostgreSQL RDS security group. Only API ECS traffic is permitted."
  vpc_id      = var.vpc_id

  egress {
    description      = "Allow outbound database traffic."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-postgres", local.name_prefix)
  })
}

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
