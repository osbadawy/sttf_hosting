# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name_prefix = "sttf-rds-"
  description = "Security group for RDS PostgreSQL instances"
  vpc_id      = aws_vpc.sttf_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sttf_api_sg.id]
    description     = "PostgreSQL access from EC2 instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "sttf-rds-sg"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "sttf_db_subnet_group" {
  name = "sttf-db-subnet-group"
  subnet_ids = [
    aws_subnet.sttf_private_subnet_1.id,
    aws_subnet.sttf_private_subnet_2.id
  ]

  tags = {
    Name        = "sttf-db-subnet-group"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Staging RDS Instance
resource "aws_db_instance" "sttf_api_staging_db" {
  identifier = "sttf-api-staging-db"

  engine         = "postgres"
  engine_version = "15.14"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  username = "sttf_admin"
  password = var.staging_db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.sttf_db_subnet_group.name

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "sttf-api-staging-db"
    Environment = "staging"
    Project     = "sttf-hosting"
  }
}

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
