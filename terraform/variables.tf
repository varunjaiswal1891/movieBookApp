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

# Spring profile on EC2 (CodeDeploy / env). Local dev uses no profile (H2 in application.yml).
variable "spring_profile" {
  description = "Spring profile for backend on EC2: stage or prod"
  type        = string
  default     = "stage"

  validation {
    condition     = contains(["stage", "prod"], var.spring_profile)
    error_message = "spring_profile must be stage or prod for deployed EC2."
  }
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
  description = "Primary Git branch for the main CodePipeline (e.g. master, main)"
  type        = string
  default     = "master"
}

variable "github_branch_secondary" {
  description = <<-EOT
    Optional second Git branch that gets its own CodePipeline (same build, deploy, and EC2 as the primary).
    Leave empty (\"\") to disable. Must not equal github_branch.
    CodePipeline can only watch one branch per pipeline, so each branch needs a separate pipeline definition.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.github_branch_secondary == "" || var.github_branch_secondary != var.github_branch
    error_message = "github_branch_secondary must be empty or different from github_branch."
  }
}

variable "enable_cicd" {
  description = "Enable CodeBuild, CodeDeploy, CodePipeline"
  type        = bool
  default     = true
}

variable "cicd_secondary_spring_profile" {
  description = "Spring profile for the secondary-branch pipeline (CodeBuild + runtime on EC2 after deploy). Only used when github_branch_secondary is non-empty."
  type        = string
  default     = "stage"

  validation {
    condition     = contains(["stage", "prod"], var.cicd_secondary_spring_profile)
    error_message = "cicd_secondary_spring_profile must be stage or prod."
  }
}

# Optional: IAM user/role ARNs allowed to upload JAR via CLI (aws s3 cp). EC2 role already has GetObject.
variable "artifacts_upload_iam_arns" {
  description = "IAM principal ARNs that may PutObject to the artifacts bucket (e.g. manual aws s3 cp from your laptop)"
  type        = list(string)
  default     = []
}

variable "ec2_root_volume_gb" {
  description = "Root EBS volume size (GiB). CodeDeploy + logs fill small disks quickly; use at least 16–20 for CI/CD nodes."
  type          = number
  default       = 20
  # AL2023 AMIs are often 8 GiB by default; undersized roots cause CodeDeploy \"No space left on device\" errors.
}