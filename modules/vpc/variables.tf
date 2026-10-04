variable "vpc_cidr" {
  type        = string
  description = "The core CIDR block for the custom production VPC network layout"
}

variable "environment" {
  type        = string
  description = "The target deployment lifecycle stage tier name tag"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR block addressing list for multi-AZ public DMZ routing tiers"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR block addressing list for private secure application workloads"
}
