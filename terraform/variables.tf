variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "db_identifier" {
  description = "The name of the RDS instance"
  type        = string
  default     = "tech-challenge-db"
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
  default     = "tech_challenge"
}

variable "db_username" {
  description = "The master username for the database"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "The master password for the database"
  type        = string
  sensitive   = true
  default     = "ChangeMe123!@#"
}

variable "db_engine_version" {
  description = "The database engine version"
  type        = string
  default     = "15.3"
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "The allocated storage in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "The maximum allocated storage in GB"
  type        = number
  default     = 500
}

variable "db_storage_type" {
  description = "The storage type (gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "db_storage_iops" {
  description = "The IOPS for gp3 storage"
  type        = number
  default     = 3000
}

variable "db_storage_throughput" {
  description = "The throughput for gp3 storage (MB/s)"
  type        = number
  default     = 125
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "enable_enhanced_monitoring" {
  description = "Enable enhanced monitoring"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
}

variable "vpc_id" {
  description = "The VPC ID where the database will be created"
  type        = string
  default     = ""
}

variable "db_subnet_group_name" {
  description = "The DB subnet group name"
  type        = string
  default     = "tech-challenge-db-subnet-group"
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for DB subnet group"
  type        = list(string)
  default     = []
}

variable "allowed_security_groups" {
  description = "Security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "tech-challenge"
    ManagedBy   = "terraform"
  }
}
