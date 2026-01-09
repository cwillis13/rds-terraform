#variable "aws_access_key" {
#  description = "AWS Access Key"
#  type        = string
#}

#variable "aws_secret_key" {
#  description = "AWS Secret Key"
#  type        = string
#}

#variable "aws_session_token" {
#  description = "AWS session token"
#  type        = string
#}

variable "enable_custom_params" {
  type    = bool
  default = false
}

variable "vpc" {
  description = "AWS account's vpc"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "prefix" {
  description = "To adhere to provisioned resource nomenclature"
  type        = string
}

variable "aws_account" {
  description = "AWS account used"
  type        = string
}

variable "app_owner" {
  description = "AD used for owning resources"
  type        = string
}

variable "infra_owner" {
  description = "AD used for owning resources"
  type        = string
}

variable "department" {
  description = "Dept owner"
  type        = string
}

variable "compliance" {
  description = "compliance designation"
  type        = string
}

variable "data_classification" {
  description = "Policy for data"
  type        = string
}

variable "schedule" {
  description = "resource schedule"
  type        = string
}

variable "project_id" {
  description = "Project number"
  type        = number
}

variable "service_now_asset" {
  description = "Asset tracking"
  type        = bool
}

variable "expense_type" {
  description = "Expense type"
  type        = string
}

variable "db_identifier" {
  description = "Database instance identifier"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in GBs"
  type        = number
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

#variable "db_iops" {
#  description = "DB iops provisioned"
#  type        = number
#}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_port" {
  description = "DB port"
  type        = string
}

#variable "db_tag" {
#  description = "Tag for the db instance"
#  type        = string
#}

variable "storage_type" {
  description = "Disk type"
  type        = string
}

variable "storage_encrypted" {
  description = "Is storage encrypted"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Whether to enable performance insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention" {
  description = "Retention of insights in days"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Emails for alerts"
  type        = list(string)
  default     = [
    "email@gmail.com"
  ]
}

variable "performance_insights_kms_key_id" {
  description = "KMS key id for insights encryption"
  type        = string
  default     = null
}

variable "monitoring_role" {
  description = "Enhanced monitoring role"
  type        = string
}

variable "mon_free_storage" {
  description = "Threshold for storage alerts"
  type        = number
}

variable "mon_cpu_thres" {
  description = "Threshold for CPU alerts"
  type        = number
}

variable "mon_free_memory" {
  description = "Threshold for memory alerts"
  type        = number
}

variable "mon_read_latency" {
  description = "Threshold for read latency alerts"
  type        = number
}

variable "mon_write_latency" {
  description = "Threshold for write latency alerts"
  type        = number
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  type        = number
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
 description = "Master password"
  type        = string
  sensitive   = true
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access rds postgres"
  type        = list(string)
}

variable "security_group" {
  description = "Security group name for RDS Postgres access"
  type        = string
}

variable "subnet_group_name" {
  description = "DB subnet group name"
  type        = string
}

variable "backup_retention_period" {
  description = "Retention for backups in days"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Backup window"
  type        = string
}

variable "publicly_accessible" {
  description = "Whether the DB instance is publicly accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Set to true to deploy Multi-AZ DB instance"
  type        = bool
  default     = false
}

variable "env" {
  description = "Overall environment of deployment"
  type        = string
}


variable "db_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
}
