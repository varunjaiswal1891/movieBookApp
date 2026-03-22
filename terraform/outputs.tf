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
