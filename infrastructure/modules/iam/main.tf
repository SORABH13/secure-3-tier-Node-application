locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })
}

resource "aws_iam_role" "task_execution" {
  name               = format("%s-task-execution-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role" "task" {
  name               = format("%s-task-role", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "task_execution_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_ecr" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0

  name   = format("%s-task-execution-secrets", local.name_prefix)
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets.json
}

data "aws_iam_policy_document" "task_execution_secrets" {
  dynamic "statement" {
    for_each = var.secret_arns
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "task_role_policy" {
  name        = format("%s-task-role-policy", local.name_prefix)
  description = "IAM policy for ECS task role to access Secrets Manager and CloudWatch Logs."

  policy = data.aws_iam_policy_document.task_role_policy.json
}

resource "aws_iam_policy_attachment" "task_role_attach" {
  name       = format("%s-task-role-policy-attach", local.name_prefix)
  policy_arn = aws_iam_policy.task_role_policy.arn
  roles      = [aws_iam_role.task.name]
}

data "aws_iam_policy_document" "task_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/ecs/*"]
  }

  dynamic "statement" {
    for_each = var.secret_arns
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = [statement.value]
    }
  }
}
