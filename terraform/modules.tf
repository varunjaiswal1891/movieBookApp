module "network" {
  source = "./modules/network"

  project_name = var.project_name
}

module "compute" {
  source = "./modules/compute"

  project_name             = var.project_name
  enable_cicd              = var.enable_cicd
  ec2_ami_owner            = var.ec2_ami_owner
  ec2_instance_type        = var.ec2_instance_type
  ec2_root_volume_gb       = var.ec2_root_volume_gb
  ssh_public_key           = var.ssh_public_key
  backend_public_subnet_id = local.backend_public_subnet_id
  backend_security_group_id = aws_security_group.backend.id
  backend_jar_s3_key       = var.backend_jar_s3_key
  aws_region               = var.aws_region
  db_host                  = aws_db_instance.main.address
  db_port                  = aws_db_instance.main.port
  db_name                  = aws_db_instance.main.db_name
  db_user                  = var.db_username
  db_password              = var.db_password
  jwt_secret               = var.jwt_secret
  posters_bucket           = aws_s3_bucket.posters.id
  spring_profile           = var.spring_profile
  artifacts_bucket         = aws_s3_bucket.artifacts.id
  artifacts_bucket_arn     = aws_s3_bucket.artifacts.arn
  posters_bucket_arn       = aws_s3_bucket.posters.arn
}
