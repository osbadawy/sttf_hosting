# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data source to get default VPC (kept for reference, but we're using custom VPC now)
# data "aws_vpc" "default" {
#   default = true
# }

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}
