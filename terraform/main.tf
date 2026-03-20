# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name            = var.db_subnet_group_name
  subnet_ids      = var.private_subnet_ids
  description     = "DB subnet group for ${var.db_identifier}"

  tags = {
    Name = var.db_subnet_group_name
  }
}

# KMS Key for encryption
resource "aws_kms_key" "rds" {
  count                   = var.enable_encryption ? 1 : 0
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${var.db_identifier}-key"
  }
}

resource "aws_kms_alias" "rds" {
  count         = var.enable_encryption ? 1 : 0
  name          = "alias/${var.db_identifier}-key"
  target_key_id = aws_kms_key.rds[0].key_id
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier            = var.db_identifier
  engine                = "postgres"
  engine_version        = var.db_engine_version
  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_iops          = var.db_storage_iops
  storage_throughput    = var.db_storage_throughput

  # Database
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Availability and Backup
  multi_az                     = var.multi_az
  backup_retention_period      = var.backup_retention_period
  backup_window                = var.backup_window
  maintenance_window           = var.maintenance_window
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot"

  # Security
  storage_encrypted = var.enable_encryption
  kms_key_id        = var.enable_encryption ? aws_kms_key.rds[0].arn : null

  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]
  enable_iam_database_authentication = true

  # Enhanced Monitoring
  monitoring_interval             = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn            = var.enable_enhanced_monitoring ? aws_iam_role.rds_monitoring[0].arn : null
  enable_performance_insights     = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id = var.enable_encryption ? aws_kms_key.rds[0].arn : null
  parameter_group_name            = aws_db_parameter_group.main.name

  # Deletion protection
  deletion_protection = true

  tags = {
    Name = var.db_identifier
  }

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.rds
  ]
}

# Parameter Group
resource "aws_db_parameter_group" "main" {
  family      = "postgres15"
  name        = "${var.db_identifier}-params"
  description = "Parameter group for ${var.db_identifier}"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_duration"
    value = "true"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pgaudit"
  }

  tags = {
    Name = "${var.db_identifier}-params"
  }
}
