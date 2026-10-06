module "network_backbone" {
  source = "./modules/vpc"

  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
}

# Container execution grid cell configuration block
module "container_compute_tier" {
  source = "./modules/ecs"

  environment        = var.environment
  vpc_id             = module.network_backbone.vpc_id
  public_subnet_ids  = module.network_backbone.public_subnet_ids
  private_subnet_ids = module.network_backbone.private_subnet_ids
}

# Output tracking string to display our live website domain address link inside GitHub logs
output "live_application_endpoint_url" {
  value       = module.container_compute_tier.load_balancer_url
  description = "The live public address to visit your enterprise application mesh"
}


# DATABASE TIER MODULE (Amazon Aurora Serverless v2)
module "database_storage_tier" {
  source = "./modules/rds"

  environment                 = var.environment
  vpc_id                      = module.network_backbone.vpc_id
  db_subnet_group_name        = module.network_backbone.db_subnet_group_name
  ecs_tasks_security_group_id = module.container_compute_tier.ecs_tasks_security_group_id
  db_password = var.db_password
}

