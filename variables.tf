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
