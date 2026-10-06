variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "Target deployment region for our enterprise environment"
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment track tag naming convention"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "The database master password passed dynamically"
}
