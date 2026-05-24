# ─────────────────────────────────────────────────────────────────────────────
# CodePipeline – GitHub → CodeBuild → CodeDeploy (single pipeline, multi-branch)
# Trigger: push to github_branch and (if set) github_branch_secondary.
# Spring profile per branch: buildspec maps CODEPIPELINE_BRANCH → profile via CodeBuild env.
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_codepipeline" "main" {
  count = var.enable_cicd ? 1 : 0

  name          = "${var.project_name}-pipeline"
  role_arn      = aws_iam_role.codepipeline[0].arn
  pipeline_type = "V2"
  execution_mode  = "QUEUED"

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = distinct(compact([var.github_branch, var.github_branch_secondary]))
        }
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.pipeline[0].bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      namespace        = "SourceVariables"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github[0].arn
        FullRepositoryId       = var.github_repo
        BranchName             = var.github_branch
        OutputArtifactFormat   = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]

      configuration = {
        ProjectName = aws_codebuild_project.main[0].name
        # Resolved at execution time; buildspec selects Spring profile from GITHUB_BRANCH_* env.
        EnvironmentVariables = jsonencode([
          {
            name  = "CODEPIPELINE_BRANCH"
            value = "#{SourceVariables.BranchName}"
            type  = "PLAINTEXT"
          }
        ])
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployBackend"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.main[0].name
        DeploymentGroupName = aws_codedeploy_deployment_group.main[0].deployment_group_name
      }
    }
  }
}
