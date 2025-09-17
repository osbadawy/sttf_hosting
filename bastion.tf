# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name_prefix = "sttf-bastion-"
  description = "Security group for Bastion Host"
  vpc_id      = aws_vpc.sttf_vpc.id

  # Allow SSH access from anywhere
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
    Name        = "sttf-bastion-sg"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sttf_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name        = "sttf-bastion"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Update EC2 security group to allow SSH from bastion
resource "aws_security_group_rule" "ec2_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.sttf_api_sg.id
  description              = "SSH access from bastion host"
}
