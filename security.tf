# Security Group for EC2 instances
resource "aws_security_group" "sttf_api_sg" {
  name_prefix = "sttf-api-"
  description = "Security group for STTF API servers"
  vpc_id      = aws_vpc.sttf_vpc.id

  # Allow traffic from ALB on port 5000
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.sttf_alb_sg.id]
    description     = "API traffic from ALB"
  }

  # Allow SSH access (optional - remove if not needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

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
