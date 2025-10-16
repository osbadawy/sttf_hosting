# TODO: Re-enable staging when needed
# Staging EC2 Instance
# resource "aws_instance" "sttf_api_staging" {
#   ami                    = data.aws_ami.amazon_linux.id
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.sttf_public_subnet_1.id
#   vpc_security_group_ids = [aws_security_group.sttf_api_sg.id]
#   iam_instance_profile   = aws_iam_instance_profile.sttf_api_profile.name
#   key_name               = var.key_pair_name
#
#   user_data = base64encode(templatefile("${path.module}/user_data_staging.sh", {
#     ecr_repository_url  = aws_ecr_repository.sttf_api.repository_url
#     aws_region          = "eu-central-1"
#     secrets_arn         = aws_secretsmanager_secret.staging_secrets.arn
#   }))
#
#   tags = {
#     Name        = "sttf-api-staging"
#     Environment = "staging"
#     Project     = "sttf-hosting"
#   }
# }

# Elastic IP for Production Instance
resource "aws_eip" "sttf_api_prod_eip" {
  instance = aws_instance.sttf_api_prod.id

  tags = {
    Name        = "sttf-api-prod-eip"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}

# Production EC2 Instance
resource "aws_instance" "sttf_api_prod" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sttf_public_subnet_2.id
  vpc_security_group_ids = [aws_security_group.sttf_api_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.sttf_api_profile.name
  key_name               = var.key_pair_name

  user_data = base64encode(templatefile("${path.module}/user_data_prod.sh", {
    ecr_repository_url = aws_ecr_repository.sttf_api.repository_url
    aws_region         = "eu-central-1"
    secrets_arn        = aws_secretsmanager_secret.prod_secrets.arn
  }))

  tags = {
    Name        = "sttf-api-prod"
    Environment = "production"
    Project     = "sttf-hosting"
  }
}