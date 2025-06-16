output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "db_instance_id" {
  value = aws_db_instance.postgres.id
}

output "db_subnet_groups" {
  value = aws_db_subnet_group.rds.name
}

output "db_security_groups" {
  value = aws_security_group.rds_access.name
}

output "db_secrets_manager" {
  value = aws_secretsmanager_secret.rds_master_credentials.name
}