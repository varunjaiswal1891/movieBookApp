# ─────────────────────────────────────────────────────────────────────────────
# Variables – customize for your environment
# ─────────────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. prod, staging)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "moviebook"
}

# ── EC2 (Backend) ───────────────────────────────────────────────────────────

variable "ec2_instance_type" {
  description = "EC2 instance type (t2.micro is free tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "ec2_ami_owner" {
  description = "AMI owner for Amazon Linux 2023"
  type        = string
  default     = "amazon"
}

# ── RDS (MySQL) ──────────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "RDS instance class (db.t3.micro is free tier eligible)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "MySQL database name"
  type        = string
  default     = "moviebookingdb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# ── Application ──────────────────────────────────────────────────────────────

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
}

variable "allowed_cidr" {
  description = "CIDR allowed to access EC2 (e.g. your IP for SSH, or 0.0.0.0/0 for public)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "backend_jar_s3_key" {
  description = "S3 key for the backend JAR (uploaded before deploy)"
  type        = string
  default     = "movie-booking-backend.jar"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
}

# ── CI/CD ────────────────────────────────────────────────────────────────────

variable "github_repo" {
  description = "GitHub repository (owner/repo or full URL for CodePipeline source)"
  type        = string
  default     = "varunjaiswal1891/movieBookApp"
}

variable "github_branch" {
  description = "Branch to deploy"
  type        = string
  default     = "master"
}

variable "enable_cicd" {
  description = "Enable CodeBuild, CodeDeploy, CodePipeline"
  type        = bool
  default     = true
}

# Optional: IAM user/role ARNs allowed to upload JAR via CLI (aws s3 cp). EC2 role already has GetObject.
variable "artifacts_upload_iam_arns" {
  description = "IAM principal ARNs that may PutObject to the artifacts bucket (e.g. manual aws s3 cp from your laptop)"
  type        = list(string)
  default     = []
}
