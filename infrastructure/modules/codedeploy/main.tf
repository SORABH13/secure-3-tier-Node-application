locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

resource "aws_codedeploy_app" "web" {
  name             = format("%s-web", local.name_prefix)
  compute_platform = "ECS"

  tags = local.common_tags
}

data "aws_iam_policy_document" "codedeploy_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy" {
  name               = format("%s-codedeploy-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# Automatic rollback: if the deployment itself fails health checks, or if any
# of the given CloudWatch alarms (ALB 5xx rate, unhealthy hosts) go into
# ALARM state during the bake window, CodeDeploy shifts traffic back to the
# blue target group without human intervention.
resource "aws_codedeploy_deployment_group" "web" {
  app_name               = aws_codedeploy_app.web.name
  deployment_group_name  = format("%s-web", local.name_prefix)
  service_role_arn       = aws_iam_role.codedeploy.arn
  deployment_config_name = var.deployment_config_name

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.web_service_name
  }

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.termination_wait_time_minutes
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.production_listener_arn]
      }

      target_group {
        name = var.blue_target_group_name
      }

      target_group {
        name = var.green_target_group_name
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events = concat(
      ["DEPLOYMENT_FAILURE"],
      length(var.alarm_names) > 0 ? ["DEPLOYMENT_STOP_ON_ALARM"] : []
    )
  }

  dynamic "alarm_configuration" {
    for_each = length(var.alarm_names) > 0 ? [1] : []
    content {
      enabled = true
      alarms  = var.alarm_names
    }
  }

  tags = local.common_tags
}
