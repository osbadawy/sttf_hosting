# Security Group for EC2 instances
resource "aws_security_group" "sttf_api_sg" {
  name_prefix = "sttf-api-"
  description = "Security group for STTF API EC2 instances"
  vpc_id      = aws_vpc.sttf_vpc.id

  # Allow HTTP traffic from anywhere (for nginx)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP (nginx)"
  }

  # Allow HTTPS traffic from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS API"
  }

  # Allow SSH access (optional - remove if not needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "sttf-api-sg"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "sttf-rds-"
  description = "Security group for RDS PostgreSQL instances"
  vpc_id      = aws_vpc.sttf_vpc.id

  # Allow PostgreSQL access from EC2 instances
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sttf_api_sg.id]
    description     = "PostgreSQL access from EC2 instances"
  }

  # Allow PostgreSQL access from VPC CIDR (for SSH tunnel connections)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.sttf_vpc.cidr_block]
    description = "PostgreSQL access from VPC CIDR"
  }

  # Allow all outbound traffic
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