output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID for the project network."
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs for the ALB and NAT gateway."
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs for the ECS tasks."
}

output "db_subnet_group_name" {
  value       = aws_db_subnet_group.main.name
  description = "Database subnet group name used by the RDS instance."
}
