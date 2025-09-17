# IAM Role for EC2 instances to access ECR
resource "aws_iam_role" "sttf_api_role" {
  name = "sttf-api-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach ECR read policy to the role
resource "aws_iam_role_policy_attachment" "sttf_api_ecr_policy" {
  role       = aws_iam_role.sttf_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach SSM policy to EC2 instances
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.sttf_api_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom policy for EC2 to access Secrets Manager
resource "aws_iam_role_policy" "secrets_manager_policy" {
  name = "sttf-secrets-manager-policy"
  role = aws_iam_role.sttf_api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.staging_secrets.arn,
          aws_secretsmanager_secret.prod_secrets.arn
        ]
      }
    ]
  })
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "sttf_api_profile" {
  name = "sttf-api-ec2-profile"
  role = aws_iam_role.sttf_api_role.name
}