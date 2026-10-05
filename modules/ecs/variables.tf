variable "environment" {
  type        = string
  description = "The target deployment lifecycle stage tier name tag"
}

variable "vpc_id" {
  type        = string
  description = "The reference ID string of our custom backbone network VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "The public subnets where the routing backend Application Load Balancer will live"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The secure private subnets where container tasks will run isolated"
}