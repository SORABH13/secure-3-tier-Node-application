locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  load_balancer_metric_name = replace(split(":", var.load_balancer_arn)[5], "loadbalancer/", "")
  target_group_metric_name  = split(":", var.target_group_arn)[5]

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          stacked = false
          region  = "${data.aws_region.current.name}"
          title   = "ALB Request Count"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", local.load_balancer_metric_name]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          view   = "timeSeries"
          region = "${data.aws_region.current.name}"
          title  = "Web ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.web_service_name]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          view   = "timeSeries"
          region = "${data.aws_region.current.name}"
          title  = "API ECS CPU Utilization"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.api_service_name]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          view   = "timeSeries"
          region = "${data.aws_region.current.name}"
          title  = "RDS CPU Utilization"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          view   = "timeSeries"
          region = "${data.aws_region.current.name}"
          title  = "Target Group Healthy Hosts"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", local.target_group_metric_name, "LoadBalancer", local.load_balancer_metric_name]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.dashboard_name
  dashboard_body = local.dashboard_body
}
