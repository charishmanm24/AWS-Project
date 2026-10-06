# ==============================================================================
# Database Firewall Rules
# ==============================================================================
resource "aws_security_group" "database_firewall_shield" {
  name        = "${var.environment}-rds-postgres-sg"
  description = "Restricts database port entry rules to verified inner container layers only"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ecs_tasks_security_group_id] # Zero Trust: Only your ECS tasks SG can hit the DB!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-database-security-group" }
}

# ==============================================================================
#Standard AWS Free-Tier PostgreSQL Instance
# ==============================================================================
resource "aws_db_instance" "postgres_data_backbone" {
  identifier             = "${var.environment}-enterprise-postgres-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.t3.micro" # 100% Free Tier Eligible compute tier size!
  allocated_storage      = 20            # 100% Free Tier Eligible storage limit bounds (20GB SSD)
  db_name                = "enterprise_app_db"
  username               = "cloud_admin_root"
  password               = "SecureEnterprisePassword2026!" # Pull this via Secrets Manager in staging tracks
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database_firewall_shield.id]
  skip_final_snapshot    = true

  tags = { Name = "${var.environment}-postgres-db-instance" }
}
