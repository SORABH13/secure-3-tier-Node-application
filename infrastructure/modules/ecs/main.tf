locals {
  name_prefix        = format("%s-%s", var.project_name, var.environment)
  cluster_name_local = var.cluster_name != "" ? var.cluster_name : format("%s-cluster", local.name_prefix)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  api_service_dns      = var.api_service_discovery_namespace != "" ? format("%s.%s", format("%s-api", local.name_prefix), var.api_service_discovery_namespace) : format("%s-api", local.name_prefix)
  api_service_endpoint = format("http://%s:%d", local.api_service_dns, var.api_service_port)
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name_local

  # Required for the RunningTaskCount / per-service CPU-Memory metrics used
  # by the CloudWatch alarms and dashboard.
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = local.cluster_name_local
  })
}

resource "aws_cloudwatch_log_group" "web" {
  name              = format("/ecs/%s-web", local.name_prefix)
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = format("%s-web-log", local.name_prefix)
  })
}

resource "aws_cloudwatch_log_group" "api" {
  name              = format("/ecs/%s-api", local.name_prefix)
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = format("%s-api-log", local.name_prefix)
  })
}

resource "aws_service_discovery_private_dns_namespace" "api" {
  count = var.api_service_discovery_namespace != "" ? 1 : 0

  name = var.api_service_discovery_namespace
  vpc  = var.vpc_id

  tags = merge(local.common_tags, {
    Name = format("%s-api-namespace", local.name_prefix)
  })
}

resource "aws_service_discovery_service" "api" {
  count = var.api_service_discovery_namespace != "" ? 1 : 0

  name         = format("%s-api", local.name_prefix)
  namespace_id = aws_service_discovery_private_dns_namespace.api[0].id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.api[0].id
    dns_records {
      type = "A"
      ttl  = 60
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ecs_task_definition" "web" {
  family                   = format("%s-web", local.name_prefix)
  cpu                      = var.web_cpu
  memory                   = var.web_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = var.web_image
      essential = true
      portMappings = [
        {
          containerPort = var.web_service_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_HOST"
          value = local.api_service_endpoint
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.web.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "web"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "api" {
  family                   = format("%s-api", local.name_prefix)
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.api_image
      essential = true
      portMappings = [
        {
          containerPort = var.api_service_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = tostring(var.api_service_port)
        },
        {
          name  = "DBHOST"
          value = var.db_host
        },
        {
          name  = "DB"
          value = var.db_name
        },
        {
          name  = "DBUSER"
          value = var.db_username
        },
        {
          name  = "DBPORT"
          value = "5432"
        }
      ]
      secrets = [
        {
          name      = "DBPASS"
          valueFrom = format("%s:password::", var.db_secret_arn)
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
}

data "aws_region" "current" {}

# Web sits behind the ALB and is user-facing, so it deploys through
# CodeDeploy blue/green (see the codedeploy module) rather than ECS-native
# rolling deployment. Terraform only creates the service and its initial
# "blue" wiring; CodeDeploy owns task_definition/load_balancer afterwards, so
# both are ignored here to avoid Terraform reverting a CodeDeploy-driven
# deployment on the next apply.
resource "aws_ecs_service" "web" {
  name             = format("%s-web", local.name_prefix)
  cluster          = aws_ecs_cluster.this.id
  desired_count    = var.web_desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  task_definition  = aws_ecs_task_definition.web.arn

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.web_security_group_id]
    assign_public_ip = false
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "web"
    container_port   = var.web_service_port
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  tags = merge(local.common_tags, {
    Name = format("%s-web-service", local.name_prefix)
  })
}

# API is internal-only (service discovery, no ALB), so CodeDeploy's
# load-balancer-based traffic shifting doesn't apply -- it uses ECS-native
# rolling deployment instead (100% minimum healthy, so old tasks stay up
# until new ones pass health checks -- zero downtime, just not blue/green).
resource "aws_ecs_service" "api" {
  name             = format("%s-api", local.name_prefix)
  cluster          = aws_ecs_cluster.this.id
  desired_count    = var.api_desired_count
  launch_type      = "FARGATE"
  platform_version = "LATEST"
  task_definition  = aws_ecs_task_definition.api.arn

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.api_security_group_id]
    assign_public_ip = false
  }

  dynamic "service_registries" {
    for_each = var.api_service_discovery_namespace != "" ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.api[0].arn
    }
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  tags = merge(local.common_tags, {
    Name = format("%s-api-service", local.name_prefix)
  })
}

resource "aws_appautoscaling_target" "web" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "web_cpu" {
  name               = format("%s-web-cpu-policy", local.name_prefix)
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web.resource_id
  scalable_dimension = aws_appautoscaling_target.web.scalable_dimension
  service_namespace  = aws_appautoscaling_target.web.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_target" "api" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = format("%s-api-cpu-policy", local.name_prefix)
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 50.0
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
