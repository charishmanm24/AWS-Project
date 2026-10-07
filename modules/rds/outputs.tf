output "database_endpoint" {
  value       = try(aws_db_instance.postgres_data_backbone.endpoint, "Provisioning")
  description = "The connection endpoint domain address of the active database storage instance"
}
