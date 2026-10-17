variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "environment" {
  type        = string
  description = "Deployment environment name used in resource tags."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets."
}
