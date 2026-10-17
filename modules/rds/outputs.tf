output "database_endpoint" {
  value       = try(aws_db_instance.main.endpoint, "Provisioning")
  description = "Endpoint address for the PostgreSQL database."
}
