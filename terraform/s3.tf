# ─────────────────────────────────────────────────────────────────────────────
# S3 – Frontend static site + backend JAR + movie posters
# ─────────────────────────────────────────────────────────────────────────────

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Frontend static files
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-frontend-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Backend JAR artifacts (for EC2 to pull)
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-artifacts-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-artifacts"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy      = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow listed IAM principals to upload JAR from laptop (aws s3 cp). Without this, only EC2 role can read.
resource "aws_s3_bucket_policy" "artifacts_upload" {
  count = length(var.artifacts_upload_iam_arns) > 0 ? 1 : 0

  bucket = aws_s3_bucket.artifacts.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ArtifactsObjectAccess"
        Effect = "Allow"
        Principal = {
          AWS = var.artifacts_upload_iam_arns
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },
      {
        Sid    = "ArtifactsListBucket"
        Effect = "Allow"
        Principal = {
          AWS = var.artifacts_upload_iam_arns
        }
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.artifacts.arn
      }
    ]
  })
}

# Movie posters (S3 bucket for app.aws config)
resource "aws_s3_bucket" "posters" {
  bucket        = "${var.project_name}-posters-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-posters"
  }
}

resource "aws_s3_bucket_public_access_block" "posters" {
  bucket = aws_s3_bucket.posters.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Pipeline artifact store (CodePipeline)
resource "aws_s3_bucket" "pipeline" {
  count = var.enable_cicd ? 1 : 0

  bucket        = "${var.project_name}-pipeline-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-pipeline"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline" {
  count = var.enable_cicd ? 1 : 0

  bucket = aws_s3_bucket.pipeline[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
