# Which cloud provider - will also prompt for aws access keys/tokens, etc
provider "aws" {
  region     = var.region
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
  #token      = var.aws_session_token

  default_tags {
    tags = {
          app-name                = var.db_identifier
          app-owner               = var.app_owner
          infra-owner             = var.app_owner
          environment             = var.env
          compliance              = var.compliance
          data-classification     = var.data_classification
          schedule                = var.schedule
          project-id              = var.project_id
          servicenowassettracking = var.service_now_asset
          expense_type            = var.expense_type
    }
  }

}

# Create a resource that will give a random suffix for various service names
resource "random_id" "suffix" {
  byte_length = 4
}

# Get all subnets in your AWS account's vpc
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    #values = [data.aws_vpc.selected.id]
    values = [var.vpc]
  }   
}

# Assign those subnets to the DB subnet group that needs to be created
resource "aws_db_subnet_group" "rds" {
  name       = "${var.prefix}-${var.db_identifier}-${var.subnet_group_name}-${var.env}"
  subnet_ids = data.aws_subnets.selected.ids
}

# Create security groups for the db instance access
resource "aws_security_group" "rds_access" {
  name        = "${var.prefix}-${var.db_identifier}-${var.security_group}-${var.env}"
  description = "Allow access to RDS Postgres"
  vpc_id      = var.vpc

  ingress {
    description = "RDS Postgres connections from allowed sources"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Create a secrets manager for master user in postgres
resource "aws_secretsmanager_secret" "rds_master_credentials" {
  name = "${var.prefix}-${var.db_identifier}-rds-master-credentials-${random_id.suffix.hex}-${var.env}"
}

resource "aws_secretsmanager_secret_version" "rds_master_credentials_version" {
  secret_id     = aws_secretsmanager_secret.rds_master_credentials.id
  secret_string = jsonencode ({
    username = var.db_username
    password = var.db_password
  })
}

data "aws_secretsmanager_secret_version" "rds_master_credentials" {
  secret_id = aws_secretsmanager_secret.rds_master_credentials.id

  depends_on = [aws_secretsmanager_secret_version.rds_master_credentials_version]
}

locals {
  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_master_credentials.secret_string)
}

# Create db paramater group resource
resource "aws_db_parameter_group" "postgres_params" {
  count           = var.enable_custom_params ? 1 : 0
  name            = "custom-postgres-params"
  family          = "postgres17"
   description     = "Custom params for db"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = "pending-reboot" # Required for static parameters
    }
  }
}

# Create the RDS instance
resource "aws_db_instance" "postgres" {
  identifier                            = var.db_identifier
  allocated_storage                     = var.allocated_storage
  engine                                = "postgres"
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  ##db_name                               = var.db_name
  db_name                               = var.db_identifier
  port                                  = var.db_port
  iam_database_authentication_enabled   = true
  username                              = local.rds_credentials.username
  password                              = local.rds_credentials.password
  db_subnet_group_name                  = aws_db_subnet_group.rds.name
  vpc_security_group_ids                = [aws_security_group.rds_access.id]
  skip_final_snapshot                   = true
  publicly_accessible                   = var.publicly_accessible
  multi_az                              = var.multi_az
  storage_type                          = var.storage_type
  storage_encrypted                     = var.storage_encrypted
  backup_retention_period               = var.backup_retention_period
  backup_window                         = var.enable_custom_params ? var.preferred_backup_window : null
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade", "iam-db-auth-error"]
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention
  monitoring_role_arn                   = var.monitoring_role
  monitoring_interval                   = var.monitoring_interval
  deletion_protection                   = true
  parameter_group_name                  = var.enable_custom_params ? aws_db_parameter_group.postgres_params[0].name : null
  
  lifecycle {
    ignore_changes = [username, password]
  }

}

resource "aws_sns_topic" "rds_alerts" {
  name = "${var.prefix}-${var.db_identifier}-alerts-${var.env}"
}

resource "aws_sns_topic_subscription" "email_alert" {
  
  for_each = toset(var.alert_email)

  topic_arn = aws_sns_topic.rds_alerts.arn
  protocol  = "email"
  #endpoint  = var.alert_email  
  endpoint  = each.value
  confirmation_timeout_in_minutes = 10

}

resource "aws_db_event_subscription" "failover_alert" {
  name          = "${var.prefix}-${var.db_identifier}-rds-failover-event-alert-${var.env}"
  sns_topic     = aws_sns_topic.rds_alerts.arn
  source_type   = "db-instance"
  event_categories = ["failover"]
  source_ids    = [aws_db_instance.postgres.identifier]
  enabled       = true
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.prefix}-${var.db_identifier}-rds-cpu-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.mon_cpu_thres
  alarm_description   = "Alarm when CPU exceeds ${var.mon_cpu_thres}"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.rds_alerts.arn]
  ok_actions    = [aws_sns_topic.rds_alerts.arn]

}

resource "aws_cloudwatch_metric_alarm" "low_storage" {
  alarm_name          = "${var.prefix}-${var.db_identifier}-low-storage-space-${var.env}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.mon_free_storage  # GB in bytes
  alarm_description   = "Triggers when free storage drops below ${var.mon_free_storage} GB"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.rds_alerts.arn]
  ok_actions    = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "read_latency" {
  alarm_name          = "${var.prefix}-${var.db_identifier}-read-latency-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReadLatency"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.mon_read_latency  # In ms
  alarm_description   = "Triggers when read latency exceeds ${var.mon_read_latency} ms"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.rds_alerts.arn]
  ok_actions    = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "write_latency" {
  alarm_name          = "${var.prefix}-${var.db_identifier}-write-latency-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "WriteLatency"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.mon_write_latency  # In ms
  alarm_description   = "Triggers when write latency exceeds ${var.mon_write_latency} ms"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.rds_alerts.arn]
  ok_actions    = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_memory" {
  alarm_name          = "${var.prefix}-${var.db_identifier}-low-freeable-memory-${var.env}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.mon_free_memory  # MB in bytes
  alarm_description   = "Triggers when freeable memory drops below ${var.mon_free_memory} MB"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.postgres.id
  }
  alarm_actions = [aws_sns_topic.rds_alerts.arn]
  ok_actions    = [aws_sns_topic.rds_alerts.arn]
}


#module "rds_dashboard" {
#  source          = "./modules/rds_dashboard"
#  dashboard_name  = "${var.prefix}-${var.db_identifier}-rds-dashboard-${var.env}"
#   db_instance_id  = var.db_identifier
#}


