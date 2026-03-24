# ─────────────────────────────────────────────────────────────────────────────
# CodePipeline – GitHub → CodeBuild → CodeDeploy
# Free tier: First 12 months free
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_codepipeline" "main" {
  count = var.enable_cicd ? 1 : 0

  name     = "${var.project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline[0].arn

  artifact_store {
    location = aws_s3_bucket.pipeline[0].bucket
    type    = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github[0].arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
        OutputArtifactFormat = "CODE_ZIP"
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
