# ─────────────────────────────────────────────────────────────────────────────
# Security Groups – EC2 (backend) and RDS (MySQL)
# ─────────────────────────────────────────────────────────────────────────────

# Backend EC2 – HTTP from CloudFront, SSH from allowed CIDR
resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "Backend EC2 - HTTP 8080, SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from CloudFront / anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg"
  }
}

# RDS MySQL – only from backend EC2
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS MySQL - 3306 from backend only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}
