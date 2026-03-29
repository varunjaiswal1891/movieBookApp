# ─────────────────────────────────────────────────────────────────────────────
# EC2 – Backend (Spring Boot)
# ─────────────────────────────────────────────────────────────────────────────

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = [var.ec2_ami_owner]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.backend.key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = aws_iam_instance_profile.backend.name

  user_data = base64encode(templatefile("${path.module}/userdata-backend.sh", {
    artifacts_bucket = aws_s3_bucket.artifacts.id
    jar_key            = var.backend_jar_s3_key
    aws_region         = var.aws_region
    db_host            = aws_db_instance.main.address
    db_port            = aws_db_instance.main.port
    db_name            = aws_db_instance.main.db_name
    db_user            = var.db_username
    db_password        = var.db_password
    jwt_secret         = var.jwt_secret
    posters_bucket     = aws_s3_bucket.posters.id
    spring_profile     = var.spring_profile
  }))

  tags = {
    Name           = "${var.project_name}-backend"
    SpringProfile  = var.spring_profile
  }
}

# SSH key – generate or use existing
resource "aws_key_pair" "backend" {
  key_name   = "${var.project_name}-backend-key"
  public_key = var.ssh_public_key

  # Avoid replace after import (EC2 rejects duplicate key name); rotate by changing key_name if needed.
  lifecycle {
    ignore_changes = [public_key]
  }
}
