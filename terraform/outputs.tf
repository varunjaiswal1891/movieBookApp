# ─────────────────────────────────────────────────────────────────────────────
# Outputs – URLs and identifiers after apply
# ─────────────────────────────────────────────────────────────────────────────

output "app_url" {
  description = "Frontend + API URL (use this in the browser)"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront Hosted Zone ID (for Route 53 alias)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "backend_ec2_public_ip" {
  description = "EC2 public IP (for SSH, direct API access)"
  value       = aws_instance.backend.public_ip
}

output "artifacts_bucket" {
  description = "S3 bucket for backend JAR"
  value       = aws_s3_bucket.artifacts.id
}

output "frontend_bucket" {
  description = "S3 bucket for frontend static files"
  value       = aws_s3_bucket.frontend.id
}

output "posters_bucket" {
  description = "S3 bucket for movie posters"
  value       = aws_s3_bucket.posters.id
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.main.endpoint
}

output "spring_profile" {
  description = "Spring profile on EC2 (stage | prod); local dev uses application.yml (H2) with no profile"
  value       = var.spring_profile
}

# CI/CD (when enable_cicd = true)
output "pipeline_url" {
  description = "CodePipeline console URL"
  value       = var.enable_cicd ? "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.main[0].name}/view" : null
}

output "pipeline_name" {
  description = "CodePipeline name (primary branch)"
  value       = var.enable_cicd ? aws_codepipeline.main[0].name : null
}

output "pipeline_url_secondary" {
  description = "CodePipeline console URL for the secondary branch (if enabled)"
  value       = var.enable_cicd && var.github_branch_secondary != "" ? "https://${var.aws_region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.secondary[0].name}/view" : null
}

output "pipeline_name_secondary" {
  description = "CodePipeline name for github_branch_secondary"
  value       = var.enable_cicd && var.github_branch_secondary != "" ? aws_codepipeline.secondary[0].name : null
}
