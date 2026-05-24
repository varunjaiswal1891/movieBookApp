variable "project_name" { type = string }
variable "enable_cicd" { type = bool }
variable "ec2_ami_owner" { type = string }
variable "ec2_instance_type" { type = string }
variable "ec2_root_volume_gb" { type = number }
variable "ssh_public_key" { type = string }
variable "backend_public_subnet_id" { type = string }
variable "backend_security_group_id" { type = string }
variable "backend_jar_s3_key" { type = string }
variable "aws_region" { type = string }
variable "db_host" { type = string }
variable "db_port" { type = number }
variable "db_name" { type = string }
variable "db_user" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "jwt_secret" {
  type      = string
  sensitive = true
}
variable "posters_bucket" { type = string }
variable "spring_profile" { type = string }
variable "artifacts_bucket" { type = string }
variable "artifacts_bucket_arn" { type = string }
variable "posters_bucket_arn" { type = string }
