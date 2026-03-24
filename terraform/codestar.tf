# ─────────────────────────────────────────────────────────────────────────────
# CodeStar Connection – GitHub (for CodePipeline source)
# After apply: Complete the connection in AWS Console → Developer Tools → Connections
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_codestarconnections_connection" "github" {
  count = var.enable_cicd ? 1 : 0

  name          = "${var.project_name}-github"
  provider_type = "GitHub"

  tags = {
    Name = "${var.project_name}-github"
  }
}

output "codestar_connection_status" {
  description = "Complete GitHub connection in AWS Console → Connections before first pipeline run"
  value       = var.enable_cicd ? "PENDING: Authorize ${var.project_name}-github in AWS Console" : "CI/CD disabled"
}
