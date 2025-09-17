# Staging EC2 Instance
resource "aws_instance" "sttf_api_staging" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sttf_api_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.sttf_api_profile.name
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data_staging.sh", {
    ecr_repository_url = aws_ecr_repository.sttf_api.repository_url
    aws_region         = "eu-central-1"
    db_endpoint        = aws_db_instance.sttf_api_staging_db.endpoint
    db_port            = aws_db_instance.sttf_api_staging_db.port
    db_name            = "sttf_api_staging"
    db_username        = "sttf_admin"
    staging_db_password = var.staging_db_password
    env_vars           = var.staging_env_vars
  }))

  tags = {
    Name        = "sttf-api-staging"
    Environment = "staging"
    Project     = "sttf-hosting"
  }
}

# Production EC2 Instance
resource "aws_instance" "sttf_api_prod" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sttf_api_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.sttf_api_profile.name
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data_prod.sh", {
    ecr_repository_url = aws_ecr_repository.sttf_api.repository_url
    aws_region         = "eu-central-1"
    db_endpoint        = aws_db_instance.sttf_api_prod_db.endpoint
    db_port            = aws_db_instance.sttf_api_prod_db.port
    db_name            = "sttf_api_prod"
    db_username        = "sttf_admin"
    prod_db_password   = var.prod_db_password
    env_vars           = var.prod_env_vars
  }))

  tags = {
    Name        = "sttf-api-prod"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}