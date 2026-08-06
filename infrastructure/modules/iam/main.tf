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

resource "aws_iam_policy" "task_role_policy" {
  name        = format("%s-task-role-policy", local.name_prefix)
  description = "IAM policy for ECS task role to access Secrets Manager and CloudWatch Logs."

  policy = data.aws_iam_policy_document.task_role_policy.json
}

data "aws_caller_identity" "current" {}

# Create an IAM role that GitHub Actions can assume via OIDC
data "aws_iam_policy_document" "github_assume_role" {
  count = var.github_oidc_provider_arn != "" && var.github_repo != "" ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [format("repo:%s:%s", var.github_repo, var.github_branch == "*" ? "*" : format("ref:refs/heads/%s", var.github_branch))]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.github_oidc_provider_arn != "" && var.github_repo != "" ? 1 : 0

  name               = var.github_actions_role_name != "" ? var.github_actions_role_name : format("%s-github-actions", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = var.github_actions_role_name != "" ? var.github_actions_role_name : format("%s-github-actions", local.name_prefix)
  })
}

resource "aws_iam_policy" "github_actions_policy" {
  count       = var.github_oidc_provider_arn != "" && var.github_repo != "" ? 1 : 0
  name        = format("%s-github-actions-policy", local.name_prefix)
  description = "Permissions used by GitHub Actions to run Terraform, push images to ECR and deploy ECS services. Review for least-privilege before production use."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:*",
          "ecs:*",
          "iam:PassRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "cloudwatch:*",
          "elasticloadbalancing:*",
          "rds:*",
          "secretsmanager:*",
          "logs:*",
          "cloudfront:*",
          "lambda:*",
          "sts:AssumeRole",
          "s3:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
  count      = var.github_oidc_provider_arn != "" && var.github_repo != "" ? 1 : 0
  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.github_actions_policy[0].arn
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
