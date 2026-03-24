# ─────────────────────────────────────────────────────────────────────────────
# CodeDeploy – Deploy backend JAR to EC2
# Free tier: EC2/on-premises deployments are free
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_codedeploy_app" "main" {
  count = var.enable_cicd ? 1 : 0

  name             = var.project_name
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "main" {
  count = var.enable_cicd ? 1 : 0

  app_name              = aws_codedeploy_app.main[0].name
  deployment_group_name  = "${var.project_name}-backend"
  service_role_arn      = aws_iam_role.codedeploy[0].arn
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "${var.project_name}-backend"
    }
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type  = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
