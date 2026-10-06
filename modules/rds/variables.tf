variable "environment" {
  type        = string
  description = "The target deployment lifecycle stage tier name tag"
}

variable "vpc_id" {
  type        = string
  description = "The reference ID string of our custom backbone network VPC"
}

variable "db_subnet_group_name" {
  type        = string
  description = "The registered database subnet group name tag token to mount our storage clusters"
}

variable "ecs_tasks_security_group_id" {
  type        = string
  description = "The security group identifier of the application containers requesting data connectivity"
}
