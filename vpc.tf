# Simple VPC Configuration - Public subnets only for cost efficiency
resource "aws_vpc" "sttf_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "sttf-vpc"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "sttf_igw" {
  vpc_id = aws_vpc.sttf_vpc.id

  tags = {
    Name        = "sttf-igw"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Public Subnet 1 (for staging EC2)
resource "aws_subnet" "sttf_public_subnet_1" {
  vpc_id                  = aws_vpc.sttf_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "sttf-public-subnet-1"
    Environment = "shared"
    Project     = "sttf-hosting"
    Type        = "public"
  }
}

# Public Subnet 2 (for production EC2)
resource "aws_subnet" "sttf_public_subnet_2" {
  vpc_id                  = aws_vpc.sttf_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "sttf-public-subnet-2"
    Environment = "shared"
    Project     = "sttf-hosting"
    Type        = "public"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "sttf_public_rt" {
  vpc_id = aws_vpc.sttf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sttf_igw.id
  }

  tags = {
    Name        = "sttf-public-rt"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Route Table Association for Public Subnet 1
resource "aws_route_table_association" "sttf_public_rta_1" {
  subnet_id      = aws_subnet.sttf_public_subnet_1.id
  route_table_id = aws_route_table.sttf_public_rt.id
}

# Route Table Association for Public Subnet 2
resource "aws_route_table_association" "sttf_public_rta_2" {
  subnet_id      = aws_subnet.sttf_public_subnet_2.id
  route_table_id = aws_route_table.sttf_public_rt.id
}