data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_secret_id
}

locals {
  db_password = try(
    jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string).password,
    data.aws_secretsmanager_secret_version.db_password.secret_string
  )
}

module "vpc" {
  source = "./modules/vpc"

  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

module "ecs" {
  source = "./modules/ecs"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "rds" {
  source = "./modules/rds"

  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  db_subnet_group_name        = module.vpc.db_subnet_group_name
  ecs_tasks_security_group_id = module.ecs.ecs_tasks_security_group_id
  db_password                 = local.db_password
}

output "application_endpoint" {
  value       = module.ecs.load_balancer_url
  description = "Public URL for the application load balancer."
}
