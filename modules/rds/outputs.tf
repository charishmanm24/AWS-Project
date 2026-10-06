output "database_endpoint" {
  value       = aws_db_instance.postgres_data_backbone.endpoint
  description = "The connection endpoint domain address of the active database storage instance"
}
