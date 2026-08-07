locals {
  name_prefix = format("%s-%s", var.project_name, var.environment)

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sourabh Yogi"
  })

  # Mirrors the ECS module's default naming so this module can scope IAM
  # resource ARNs without depending on the ecs module's outputs (the ecs
  # module already depends on this module's role ARNs, so depending on ecs
  # here would be a cycle).
  ecs_cluster_name = format("%s-cluster", local.name_prefix)
  ecs_web_service  = format("%s-web", local.name_prefix)
  ecs_api_service  = format("%s-api", local.name_prefix)

  # Mirrors the codedeploy module's naming (see infrastructure/modules/codedeploy).
  # Not referenced via module output: codedeploy depends on ecs, which depends
  # on this module's role ARNs, so an iam -> codedeploy reference would cycle.
  codedeploy_app_name = format("%s-web", local.name_prefix)

  github_oidc_enabled = var.enable_github_oidc && var.github_repository != ""
  github_subjects = [
    for ref in var.github_allowed_refs : format("repo:%s:ref:refs/heads/%s", var.github_repository, ref)
  ]
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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

# --- GitHub Actions OIDC federation ------------------------------------
# Replaces long-lived AWS_ACCESS_KEY_ID/SECRET GitHub Secrets with short-lived
# tokens minted per workflow run. Trust is scoped to this exact repository and
# to specific branch refs, so no other repo or fork can assume these roles.
resource "aws_iam_openid_connect_provider" "github" {
  count = local.github_oidc_enabled ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # AWS now validates GitHub's OIDC token against its own trusted CA store
  # rather than this thumbprint, but the field is still required by the API.
  # This is GitHub's published intermediate CA thumbprint (rotated 2023).
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = merge(local.common_tags, {
    Name = format("%s-github-oidc", local.name_prefix)
  })
}

data "aws_iam_policy_document" "github_assume_role" {
  count = local.github_oidc_enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

# --- App deploy role: build/push images + roll ECS services -----------
# Deliberately excludes VPC/IAM/RDS/etc so a compromised app-deploy token
# cannot touch anything outside the two ECR repos and the two ECS services.
resource "aws_iam_role" "github_app_deploy" {
  count = local.github_oidc_enabled ? 1 : 0

  name               = format("%s-gha-app-deploy", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_app_deploy" {
  count = local.github_oidc_enabled ? 1 : 0

  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
    ]
    resources = var.ecr_repository_arns
  }

  statement {
    sid    = "EcsDeploy"
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
    ]
    resources = [
      format("arn:aws:ecs:%s:%s:service/%s/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.ecs_cluster_name, local.ecs_web_service),
      format("arn:aws:ecs:%s:%s:service/%s/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.ecs_cluster_name, local.ecs_api_service),
      format("arn:aws:ecs:%s:%s:task-definition/%s:*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.ecs_web_service),
      format("arn:aws:ecs:%s:%s:task-definition/%s:*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.ecs_api_service),
    ]
  }

  # Blue/green deploys of the Web service register a new task definition
  # revision and hand it to CodeDeploy, instead of calling UpdateService
  # directly (CodeDeploy owns the cutover -- see the codedeploy module).
  statement {
    sid       = "EcsRegisterTaskDefinition"
    effect    = "Allow"
    actions   = ["ecs:RegisterTaskDefinition"]
    resources = ["*"] # RegisterTaskDefinition does not support resource-level scoping.
  }

  statement {
    sid     = "PassEcsRoles"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.task_execution.arn,
      aws_iam_role.task.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "CodeDeployWebRollout"
    effect = "Allow"
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
    ]
    resources = [
      format("arn:aws:codedeploy:%s:%s:application:%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.codedeploy_app_name),
      format("arn:aws:codedeploy:%s:%s:deploymentgroup:%s/*", data.aws_region.current.name, data.aws_caller_identity.current.account_id, local.codedeploy_app_name),
      format("arn:aws:codedeploy:%s:%s:deploymentconfig:*", data.aws_region.current.name, data.aws_caller_identity.current.account_id),
    ]
  }
}

resource "aws_iam_role_policy" "github_app_deploy" {
  count = local.github_oidc_enabled ? 1 : 0

  name   = format("%s-gha-app-deploy-policy", local.name_prefix)
  role   = aws_iam_role.github_app_deploy[0].id
  policy = data.aws_iam_policy_document.github_app_deploy[0].json
}

# --- Terraform role: manages the full stack ----------------------------
# Scoped to the exact set of AWS services this project's Terraform code
# touches (see infrastructure/modules/*), not full AdministratorAccess. Still
# broad within those services -- the compensating controls are (a) trust is
# limited to this repo/branch via OIDC, and (b) infra.yml requires a manual
# approval gate (GitHub environment protection) before apply runs.
resource "aws_iam_role" "github_terraform" {
  count = local.github_oidc_enabled ? 1 : 0

  name               = format("%s-gha-terraform", local.name_prefix)
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "github_terraform" {
  count = local.github_oidc_enabled ? 1 : 0

  statement {
    sid    = "StackServices"
    effect = "Allow"
    actions = [
      "ec2:*",
      "ecs:*",
      "ecr:*",
      "elasticloadbalancing:*",
      "cloudfront:*",
      "wafv2:*",
      "cloudtrail:*",
      "backup:*",
      "kms:*",
      "secretsmanager:*",
      "iam:*",
      "logs:*",
      "sns:*",
      "cloudwatch:*",
      "application-autoscaling:*",
      "servicediscovery:*",
      "acm:*",
      "rds:*",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformStateBackend"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = ["arn:aws:s3:::toptal-yogi-project", "arn:aws:s3:::toptal-yogi-project/*"]
  }

  statement {
    sid       = "TerraformStateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = ["arn:aws:dynamodb:*:*:table/deploystar-state-locks"]
  }
}

resource "aws_iam_role_policy" "github_terraform" {
  count = local.github_oidc_enabled ? 1 : 0

  name   = format("%s-gha-terraform-policy", local.name_prefix)
  role   = aws_iam_role.github_terraform[0].id
  policy = data.aws_iam_policy_document.github_terraform[0].json
}
