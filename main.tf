terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws",
      version = "~> 3.5.0"
    }
  }
}


provider "aws" {
  region = "eu-central-1"
}

# ECR Repository
resource "aws_ecr_repository" "sttf_api" {
  name = "sttf-api"
}

# Outputs
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