# ECR Outputs
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.sttf_api.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.sttf_api.arn
}

output "ecr_registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.sttf_api.registry_id
}

# EC2 Outputs
output "staging_instance_id" {
  description = "The ID of the staging EC2 instance"
  value       = aws_instance.sttf_api_staging.id
}

output "staging_instance_public_ip" {
  description = "The public IP of the staging EC2 instance"
  value       = aws_instance.sttf_api_staging.public_ip
}

output "staging_instance_public_dns" {
  description = "The public DNS of the staging EC2 instance"
  value       = aws_instance.sttf_api_staging.public_dns
}

output "prod_instance_id" {
  description = "The ID of the production EC2 instance"
  value       = aws_instance.sttf_api_prod.id
}

output "prod_instance_public_ip" {
  description = "The public IP of the production EC2 instance"
  value       = aws_instance.sttf_api_prod.public_ip
}

output "prod_instance_public_dns" {
  description = "The public DNS of the production EC2 instance"
  value       = aws_instance.sttf_api_prod.public_dns
}

# RDS Outputs
output "staging_db_endpoint" {
  description = "The endpoint of the staging RDS instance"
  value       = aws_db_instance.sttf_api_staging_db.endpoint
}

output "staging_db_port" {
  description = "The port of the staging RDS instance"
  value       = aws_db_instance.sttf_api_staging_db.port
}

output "staging_db_name" {
  description = "The name of the staging database"
  value       = "sttf_api_staging"
}

output "prod_db_endpoint" {
  description = "The endpoint of the production RDS instance"
  value       = aws_db_instance.sttf_api_prod_db.endpoint
}

output "prod_db_port" {
  description = "The port of the production RDS instance"
  value       = aws_db_instance.sttf_api_prod_db.port
}

output "prod_db_name" {
  description = "The name of the production database"
  value       = "sttf_api_prod"
}
