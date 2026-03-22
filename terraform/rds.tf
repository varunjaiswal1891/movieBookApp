# ─────────────────────────────────────────────────────────────────────────────
# RDS MySQL - Free tier: db.t3.micro (db.t2.micro deprecated for MySQL 8)
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet"
  }
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project_name}-db"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class   = var.db_instance_class
  allocated_storage = 20
  storage_type     = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az             = false

  backup_retention_period = 1
  skip_final_snapshot     = true

  tags = {
    Name = "${var.project_name}-mysql"
  }
}
