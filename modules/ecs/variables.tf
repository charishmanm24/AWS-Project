variable "environment" {
  type        = string
  description = "Deployment environment name used in resource tags."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for the ALB and ECS tasks."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the ALB."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the ECS tasks."
}