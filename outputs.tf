# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.sttf_vpc.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.sttf_vpc.cidr_block
}

# ECR Information
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.sttf_api.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.sttf_api.arn
}

output "ecr_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = aws_ecr_repository.sttf_api.registry_id
}

# TODO: Re-enable staging when needed
# Staging Instance Information
# output "staging_instance_id" {
#   description = "ID of the staging EC2 instance"
#   value       = aws_instance.sttf_api_staging.id
# }
#
# output "staging_instance_public_ip" {
#   description = "Public IP of the staging EC2 instance"
#   value       = aws_instance.sttf_api_staging.public_ip
# }
#
# output "staging_instance_public_dns" {
#   description = "Public DNS of the staging EC2 instance"
#   value       = aws_instance.sttf_api_staging.public_dns
# }
#
# output "staging_api_url" {
#   description = "URL to access the staging API"
#   value       = "http://${aws_instance.sttf_api_staging.public_ip}:5000"
# }
#
# output "staging_health_url" {
#   description = "URL to check staging API health"
#   value       = "http://${aws_instance.sttf_api_staging.public_ip}:5000/health"
# }
#
# output "ssh_connection_staging" {
#   description = "SSH command to connect to the staging EC2 instance"
#   value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_instance.sttf_api_staging.public_ip}"
# }
#
# # Staging RDS Information
# output "staging_db_endpoint" {
#   description = "Endpoint of the staging RDS instance"
#   value       = "${aws_db_instance.sttf_api_staging_db.endpoint}:${aws_db_instance.sttf_api_staging_db.port}"
# }
#
# output "staging_db_name" {
#   description = "Name of the staging database"
#   value       = "sttf_api_staging"
# }
#
# output "staging_db_port" {
#   description = "Port of the staging database"
#   value       = aws_db_instance.sttf_api_staging_db.port
# }

# Production Instance Information
output "prod_instance_id" {
  description = "ID of the production EC2 instance"
  value       = aws_instance.sttf_api_prod.id
}

output "prod_instance_public_ip" {
  description = "Public IP of the production EC2 instance (Elastic IP)"
  value       = aws_eip.sttf_api_prod_eip.public_ip
}

output "prod_instance_public_dns" {
  description = "Public DNS of the production EC2 instance"
  value       = aws_instance.sttf_api_prod.public_dns
}

output "api_url" {
  description = "URL to access the production API"
  value       = "http://${aws_eip.sttf_api_prod_eip.public_ip}:5000"
}

output "prod_health_url" {
  description = "URL to check production API health"
  value       = "http://${aws_eip.sttf_api_prod_eip.public_ip}:5000/health"
}

output "ssh_connection_prod" {
  description = "SSH command to connect to the production EC2 instance"
  value       = "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${aws_eip.sttf_api_prod_eip.public_ip}"
}

# Production RDS Information
output "prod_db_endpoint" {
  description = "Endpoint of the production RDS instance"
  value       = "${aws_db_instance.sttf_api_prod_db.endpoint}:${aws_db_instance.sttf_api_prod_db.port}"
}

output "prod_db_name" {
  description = "Name of the production database"
  value       = "sttf_api_prod"
}

output "prod_db_port" {
  description = "Port of the production database"
  value       = aws_db_instance.sttf_api_prod_db.port
}

output "prod_db_host" {
  description = "Host of the production RDS instance"
  value       = aws_db_instance.sttf_api_prod_db.endpoint
}

output "prod_db_hostname" {
  description = "Hostname of the production RDS instance (without port)"
  value       = split(":", aws_db_instance.sttf_api_prod_db.endpoint)[0]
}