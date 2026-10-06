output "database_endpoint" {
  value       = aws_rds_cluster.aurora_data_backbone.endpoint
  description = "The connection endpoint domain address of the active database storage cluster"
}
