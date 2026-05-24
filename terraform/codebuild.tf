# ─────────────────────────────────────────────────────────────────────────────
# CodeBuild – Build backend JAR + frontend, deploy frontend to S3, output for CodeDeploy
# Free tier: 100 build min/month (BUILD_GENERAL1_SMALL)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_codebuild_project" "main" {
  count = var.enable_cicd ? 1 : 0

  name          = "${var.project_name}-build"
  description   = "Build backend + frontend, deploy frontend to S3; one project shared by all pipelines (single EC2 deploy target)"
  service_role  = aws_iam_role.codebuild[0].arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    # Valid values: CODEBUILD (managed images) or SERVICE_ROLE (private registry)
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ARTIFACTS_BUCKET"
      value = aws_s3_bucket.artifacts.id
    }
    environment_variable {
      name  = "FRONTEND_BUCKET"
      value = aws_s3_bucket.frontend.id
    }
    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = aws_cloudfront_distribution.main.id
    }
    environment_variable {
      name  = "VITE_API_BASE_URL"
      value = "/api"
    }
    environment_variable {
      name  = "SPRING_PROFILES_ACTIVE"
      value = var.spring_profile
    }
    # Matched in buildspec against CODEPIPELINE_BRANCH (set by pipeline from the Git push).
    environment_variable {
      name  = "SPRING_PROFILE_PRIMARY"
      value = var.spring_profile
    }
    environment_variable {
      name  = "SPRING_PROFILE_SECONDARY"
      value = var.cicd_secondary_spring_profile
    }
    environment_variable {
      name  = "GITHUB_BRANCH_PRIMARY"
      value = var.github_branch
    }
    environment_variable {
      name  = "GITHUB_BRANCH_SECONDARY"
      value = var.github_branch_secondary
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build"
    }
  }

  tags = {
    Name = "${var.project_name}-build"
  }
}
