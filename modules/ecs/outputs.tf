output "load_balancer_url" {
  value       = aws_lb.main.dns_name
  description = "Public DNS name for the application load balancer."
}

output "ecs_tasks_security_group_id" {
  value       = aws_security_group.app.id
  description = "Security group ID used by the ECS tasks for inbound access from the ALB."
}
