# ─────────────────────────────────────────────────────────────────────────────
# Network alignment – keep backend EC2 in the same VPC as existing RDS
# This prevents cross-VPC DB connectivity failures after partial re-creates.
# ─────────────────────────────────────────────────────────────────────────────

data "aws_db_subnet_group" "existing" {
  name = aws_db_subnet_group.main.name
}

data "aws_subnets" "existing_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_db_subnet_group.existing.vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-public-*"]
  }
}

data "aws_db_instance" "current" {
  db_instance_identifier = aws_db_instance.main.identifier
}

locals {
  backend_vpc_id          = data.aws_db_subnet_group.existing.vpc_id
  backend_public_subnet_id = sort(data.aws_subnets.existing_public.ids)[0]
}

# Apply backend SG access on the DB's currently attached SGs.
resource "aws_security_group_rule" "rds_allow_backend_runtime" {
  for_each = toset(data.aws_db_instance.current.vpc_security_groups)

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = each.value
  source_security_group_id = aws_security_group.backend.id
  description              = "MySQL from backend SG (runtime DB SG)"
}
