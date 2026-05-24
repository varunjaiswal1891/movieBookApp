data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = [var.ec2_ami_owner]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_iam_role" "backend" {
  name = "${var.project_name}-backend-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "backend_s3" {
  name = "${var.project_name}-backend-s3"
  role = aws_iam_role.backend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.artifacts_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.posters_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backend_codedeploy" {
  count = var.enable_cicd ? 1 : 0

  role       = aws_iam_role.backend.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "backend" {
  name = "${var.project_name}-backend-profile"
  role = aws_iam_role.backend.name
}

resource "aws_key_pair" "backend" {
  key_name   = "${var.project_name}-backend-key"
  public_key = var.ssh_public_key

  lifecycle {
    ignore_changes = [public_key]
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.backend.key_name
  subnet_id              = var.backend_public_subnet_id
  vpc_security_group_ids = [var.backend_security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.backend.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.ec2_root_volume_gb
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.root}/userdata-backend.sh", {
    artifacts_bucket = var.artifacts_bucket
    jar_key          = var.backend_jar_s3_key
    aws_region       = var.aws_region
    db_host          = var.db_host
    db_port          = var.db_port
    db_name          = var.db_name
    db_user          = var.db_user
    db_password      = var.db_password
    jwt_secret       = var.jwt_secret
    posters_bucket   = var.posters_bucket
    spring_profile   = var.spring_profile
  }))

  tags = {
    Name          = "${var.project_name}-backend"
    SpringProfile = var.spring_profile
  }
}
