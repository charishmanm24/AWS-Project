# ==============================================================================
# DATA LAYER SECURITY (Zero-Trust Isolated Database Firewall Rules)
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
# SERVERLESS DATA COMPUTE (Amazon Aurora Cluster Definitions)
# ==============================================================================
resource "aws_rds_cluster" "aurora_data_backbone" {
  cluster_identifier  = "${var.environment}-aurora-postgres-cluster"
  engine              = "aurora-postgresql"
  engine_mode         = "provisioned" # Required setting allocation strategy mode for Serverless v2
  engine_version      = "15.4"
  database_name       = "enterprise_app_db"
  master_username     = "cloud_admin_root"
  master_password     = "SecureEnterprisePassword2026!" # In production, pull this from AWS Secrets Manager
  skip_final_snapshot = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.database_firewall_shield.id]

  # Cleaned Inline Scaling Block for Serverless v2 Core Configurations
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  tags = { Name = "${var.environment}-aurora-cluster" }
}

# The Active Dynamic Serverless Instance Computing Cell Node
resource "aws_rds_cluster_instance" "aurora_compute_node" {
  cluster_identifier  = aws_rds_cluster.aurora_data_backbone.id
  instance_class      = "db.serverless" # Binds instance behavior to scaling ranges above
  engine              = aws_rds_cluster.aurora_data_backbone.engine
  engine_version      = aws_rds_cluster.aurora_data_backbone.engine_version
  publicly_accessible = false

  tags = { Name = "${var.environment}-aurora-instance-1" }
}
