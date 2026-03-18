output "rds_endpoint_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.main.address
}

output "rds_endpoint_port" {
  description = "The port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "rds_endpoint_full" {
  description = "The full connection endpoint"
  value       = "${aws_db_instance.main.address}:${aws_db_instance.main.port}"
}

output "rds_database_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}

output "rds_master_username" {
  description = "The master username"
  value       = aws_db_instance.main.username
}

output "rds_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_resource_id" {
  description = "The RDS resource ID"
  value       = aws_db_instance.main.resource_id
}

output "rds_security_group_id" {
  description = "The security group ID"
  value       = aws_security_group.rds.id
}

output "connection_string" {
  description = "PostgreSQL connection string"
  value       = "postgresql://${aws_db_instance.main.username}:PASSWORD@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "jdbc_connection_string" {
  description = "JDBC connection string for Java applications"
  value       = "jdbc:postgresql://${aws_db_instance.main.address}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}
