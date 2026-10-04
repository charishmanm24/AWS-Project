output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The generated reference token identifier of the backbone network VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List containing the resource IDs of the generated public subnet routing grid"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "List containing the resource IDs of the generated private isolated subnet layout"
}
