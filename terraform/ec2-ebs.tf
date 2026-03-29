# ─────────────────────────────────────────────────────────────────────────────
# EC2 root volume – sized for CodeDeploy agents, JARs, and logs (AL2023 AMI default is small)
# ─────────────────────────────────────────────────────────────────────────────

variable "ec2_root_volume_gb" {
  description = "Root EBS volume size (GiB). CodeDeploy + logs fill small disks quickly; use at least 16–20 for CI/CD nodes."
  type        = number
  default     = 20
  # AL2023 AMIs are often 8 GiB by default; undersized roots cause CodeDeploy "No space left on device" errors.
}
