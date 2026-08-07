locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

#tfsec:ignore:aws-elb-alb-not-public -- required to be internet-facing per
# the assignment ("Web tier publicly accessible"); this is CloudFront/WAF's
# origin, not something end users hit directly, but it must accept traffic
# from CloudFront's changing IP ranges, so it can't be made internal.
resource "aws_lb" "this" {
  name                       = format("%s-alb", local.name_prefix)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.security_group_id]
  subnets                    = var.subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(local.common_tags, {
    Name = format("%s-alb", local.name_prefix)
  })
}

# Kept as the original name/address ("web", not "web_blue") so this stays the
# same target group already attached to the live ALB listener and ECS
# service -- renaming it would force a replacement (target group `name` is
# immutable) and detach live traffic. It plays the "blue" role in the
# CodeDeploy blue/green deployment group below.
resource "aws_lb_target_group" "web" {
  name        = format("%s-web-tg", local.name_prefix)
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = format("%s-web-tg", local.name_prefix)
  })
}

# CodeDeploy blue/green target group for the Web ECS service. CodeDeploy
# shifts the listener's forward rule between "web" (blue) and "web_green"
# on each deployment -- Terraform only owns their existence, not which one is
# currently live (see the ecs module's lifecycle.ignore_changes on the
# service's load_balancer block).
resource "aws_lb_target_group" "web_green" {
  name        = format("%s-web-tg-green", local.name_prefix)
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = format("%s-web-tg-green", local.name_prefix)
  })
}

#tfsec:ignore:aws-elb-http-not-used -- only exists when certificate_arn is
# unset (see terraform.tfvars.example); the moment a real ACM cert is
# supplied, this listener disappears in favor of http_redirect+https below.
resource "aws_lb_listener" "http" {
  count             = var.certificate_arn == "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_lb_listener" "http_redirect" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2023-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
