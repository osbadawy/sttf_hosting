# DB Parameter Group
resource "aws_db_parameter_group" "sttf_db_parameter_group" {
  family = "postgres15"
  name   = "sttf-db-parameter-group"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = {
    Name        = "sttf-db-parameter-group"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "sttf_db_subnet_group" {
  name = "sttf-db-subnet-group"
  subnet_ids = [
    aws_subnet.sttf_public_subnet_1.id,
    aws_subnet.sttf_public_subnet_2.id
  ]

  tags = {
    Name        = "sttf-db-subnet-group"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# TODO: Re-enable staging when needed
# Staging RDS Instance
# resource "aws_db_instance" "sttf_api_staging_db" {
#   identifier = "sttf-api-staging-db"
#
#   engine         = "postgres"
#   engine_version = "15.14"
#   instance_class = "db.t3.micro"
#
#   allocated_storage     = 20
#   max_allocated_storage = 100
#   storage_type          = "gp2"
#   storage_encrypted     = true
#
#   username = "sttf_admin"
#   password = var.staging_db_password
#
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   db_subnet_group_name   = aws_db_subnet_group.sttf_db_subnet_group.name
#
#   backup_retention_period = 7
#   backup_window           = "03:00-04:00"
#   maintenance_window      = "sun:04:00-sun:05:00"
#
#   skip_final_snapshot = true
#   deletion_protection = false
#
#   tags = {
#     Name        = "sttf-api-staging-db"
#     Environment = "staging"
#     Project     = "sttf-hosting"
#   }
# }

# Production RDS Instance
resource "aws_db_instance" "sttf_api_prod_db" {
  identifier = "sttf-api-prod-db"

  engine         = "postgres"
  engine_version = "15.14"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  username = "sttf_admin"
  password = var.prod_db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.sttf_db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.sttf_db_parameter_group.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "sttf-api-prod-db"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}