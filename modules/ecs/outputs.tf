output "load_balancer_url" {
  value       = aws_lb.application_routing_hub.dns_name
  description = "The public web DNS endpoint link address used to access our live active application"
}

output "ecs_tasks_security_group_id" {
  value       = aws_security_group.container_workload_isolation.id
  description = "The container tasks firewall token used to whitelist inbound database access rules"
}
