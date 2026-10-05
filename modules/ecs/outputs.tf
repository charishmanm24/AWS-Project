output "load_balancer_url" {
  value       = aws_lb.application_routing_hub.dns_name
  description = "The public web DNS endpoint link address used to access our live active application"
}