variable "region" {
  type        = string
  default     = "ap-south-1"
  description = "Target deployment region for the project."
}

variable "environment" {
  type        = string
  default     = "prod"
  description = "Deployment name used in resource tags."
}

variable "db_secret_id" {
  type        = string
  description = "ARN or name of the Secrets Manager secret containing the PostgreSQL password."
}
