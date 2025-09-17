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

# ALB Outputs
output "prod_alb_dns_name" {
  description = "The DNS name of the Production Application Load Balancer"
  value       = aws_lb.sttf_prod_alb.dns_name
}

output "prod_alb_zone_id" {
  description = "The zone ID of the Production Application Load Balancer"
  value       = aws_lb.sttf_prod_alb.zone_id
}

output "prod_alb_arn" {
  description = "The ARN of the Production Application Load Balancer"
  value       = aws_lb.sttf_prod_alb.arn
}

output "staging_alb_dns_name" {
  description = "The DNS name of the Staging Application Load Balancer"
  value       = aws_lb.sttf_staging_alb.dns_name
}

output "staging_alb_zone_id" {
  description = "The zone ID of the Staging Application Load Balancer"
  value       = aws_lb.sttf_staging_alb.zone_id
}

output "staging_alb_arn" {
  description = "The ARN of the Staging Application Load Balancer"
  value       = aws_lb.sttf_staging_alb.arn
}

# Domain Outputs
output "api_domain_name" {
  description = "The domain name for the production API (if configured)"
  value       = var.domain_name != "" ? var.domain_name : "No domain configured - use ALB DNS name"
}

output "staging_api_domain_name" {
  description = "The domain name for the staging API (if configured)"
  value       = var.domain_name != "" ? "staging.${var.domain_name}" : "No domain configured - use ALB DNS name"
}

output "api_url" {
  description = "The URL for the production API"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.sttf_prod_alb.dns_name}"
}

output "staging_api_url" {
  description = "The URL for the staging API"
  value       = var.domain_name != "" ? "https://staging.${var.domain_name}" : "http://${aws_lb.sttf_staging_alb.dns_name}"
}

# SSL Certificate Outputs (only if domain is configured)
output "ssl_certificate_arn" {
  description = "The ARN of the SSL certificate (if domain is configured)"
  value       = var.domain_name != "" ? aws_acm_certificate.sttf_cert[0].arn : "No SSL certificate - using HTTP only"
}

# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.sttf_vpc.id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.sttf_vpc.cidr_block
}

# Bastion Host Outputs
output "bastion_public_ip" {
  description = "The public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  description = "The public DNS of the bastion host"
  value       = aws_instance.bastion.public_dns
}

output "ssh_connection_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.bastion.public_ip}"
}

output "ssh_to_ec2_command" {
  description = "SSH command to connect to EC2 instances via bastion"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem -J ec2-user@${aws_instance.bastion.public_ip} ec2-user@<PRIVATE_IP>"
}

output "prod_db_name" {
  description = "The name of the production database"
  value       = "sttf_api_prod"
}
