# Which cloud provider - will prompt for aws access keys/tokens - used for ad-hoc deployments
provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
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
  name       = "${var.subnet_group_name}-${var.env}"
  subnet_ids = data.aws_subnets.selected.ids

  tags = {
    Name = "RDS subnet group"
    Environment = var.env
  }
}

# Create security groups for the db instance access
resource "aws_security_group" "rds_access" {
  name        = "${var.security_group}-${var.env}"
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

  tags = {
    Name        = "RDS Access Security Group"
    Environment = var.env
  }

}

# Create a secrets manager for master user in postgres
resource "aws_secretsmanager_secret" "rds_master_credentials" {
  name = "rds-master-credentials-${random_id.suffix.hex}-${var.env}"
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

# Create the RDS instance
resource "aws_db_instance" "postgres" {
  identifier                            = var.db_identifier
  allocated_storage                     = var.allocated_storage
  engine                                = "postgres"
  engine_version                        = var.engine_version
  instance_class                        = var.instance_class
  db_name                               = var.db_name
  port                                  = var.db_port
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
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention
  monitoring_role_arn                   = var.monitoring_role
  monitoring_interval                   = var.monitoring_interval
  tags = {
    Name = var.db_tag
    Environment = var.env
  }
}
