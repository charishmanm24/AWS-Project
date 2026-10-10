variable "environment" {
  type        = string
  description = "The target deployment lifecycle stage name tag"
}

variable "vpc_id" {
  type        = string
  description = "The reference ID string of the custom network VPC"
}

variable "db_subnet_group_name" {
  type        = string
  description = "The registered database subnet group name tag token to mount our storage clusters"
}

variable "ecs_tasks_security_group_id" {
  type        = string
  description = "The security group identifier of the application containers requesting data connectivity"
}

variable "db_password" {
  type        = string
  sensitive   = true # <-- Tells Terraform to hide this password in all console logs
  description = "The root master password for the PostgreSQL database instance"
}