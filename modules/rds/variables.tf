variable "environment" {
  type        = string
  description = "Deployment environment name used in resource tags."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the database security group."
}

variable "db_subnet_group_name" {
  type        = string
  description = "Subnet group used by the RDS instance."
}

variable "ecs_tasks_security_group_id" {
  type        = string
  description = "Security group ID for the ECS tasks that are allowed to reach PostgreSQL."
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL password loaded from AWS Secrets Manager."
}