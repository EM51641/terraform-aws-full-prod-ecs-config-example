data "aws_iam_policy_document" "github_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.project_name}-${var.env_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
}

data "aws_iam_policy_document" "github_actions_policy" {

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices"
    ]
    resources = [var.service_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:container-memory"
      values   = [var.ecs_task_memory]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:container-cpu"
      values   = [var.ecs_task_cpu]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:TaskRoleArn"
      values   = [var.ecs_task_role_arn]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:ExecutionRoleArn"
      values   = [var.ecs_execution_role_arn]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:requiresCompatibilities"
      values   = ["FARGATE"]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:networkMode"
      values   = ["awsvpc"]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:family"
      values   = [var.ecs_family]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:containerDefinitions[0].name"
      values   = ["${var.project_name}-${var.env_name}-ecs-task"]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "ecs:containerDefinitions[0].logConfiguration.logDriver"
      values   = ["awslogs"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeTaskDefinition"
    ]
    resources = [var.service_arn]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      var.ecs_task_role_arn,
      var.ecs_execution_role_arn,
      var.batch_ecs_task_execution_role_arn,
      var.batch_ecs_task_role_arn
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
    resources = [var.ecr_repository_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      var.s3_bucket_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${var.s3_bucket_arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionConfiguration",
      "lambda:UpdateFunctionCode",
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = [var.lambda_function_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "batch:RegisterJobDefinition",
      "batch:DescribeJobDefinition",
      "batch:DescribeJobs",
      "batch:SubmitJob"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "github_actions" {
  name   = "${var.project_name}-${var.env_name}-github-actions-ecs-policy"
  policy = data.aws_iam_policy_document.github_actions_policy.json

  tags = {
    Name        = "${var.project_name}-${var.env_name}-github-actions-policy"
    Environment = var.env_name
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
