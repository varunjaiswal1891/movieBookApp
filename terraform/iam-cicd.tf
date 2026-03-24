# ─────────────────────────────────────────────────────────────────────────────
# IAM – CodeBuild, CodePipeline, CodeDeploy
# ─────────────────────────────────────────────────────────────────────────────

# CodeBuild service role
resource "aws_iam_role" "codebuild" {
  count = var.enable_cicd ? 1 : 0

  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  count = var.enable_cicd ? 1 : 0

  name   = "${var.project_name}-codebuild-policy"
  role   = aws_iam_role.codebuild[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/*",
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.main.arn
      }
    ]
  })
}

# CodePipeline service role
resource "aws_iam_role" "codepipeline" {
  count = var.enable_cicd ? 1 : 0

  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  count = var.enable_cicd ? 1 : 0

  name   = "${var.project_name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.artifacts.arn}/*",
          "${aws_s3_bucket.pipeline[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds", "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.main[0].arn
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment", "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision", "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig", "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["iam:PassRole"]
        Resource = aws_iam_role.codebuild[0].arn
        Condition = {
          StringEquals = { "iam:PassedToService" = "codebuild.amazonaws.com" }
        }
      }
    ]
  })
}

# CodeDeploy service role (for CodeDeploy service itself)
resource "aws_iam_role" "codedeploy" {
  count = var.enable_cicd ? 1 : 0

  name = "${var.project_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  count = var.enable_cicd ? 1 : 0

  role       = aws_iam_role.codedeploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
