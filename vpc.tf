# VPC Configuration for ALB
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

# Public Subnets for ALB
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

# Private Subnets for EC2 instances
resource "aws_subnet" "sttf_private_subnet_1" {
  vpc_id            = aws_vpc.sttf_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "sttf-private-subnet-1"
    Environment = "shared"
    Project     = "sttf-hosting"
    Type        = "private"
  }
}

resource "aws_subnet" "sttf_private_subnet_2" {
  vpc_id            = aws_vpc.sttf_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "sttf-private-subnet-2"
    Environment = "shared"
    Project     = "sttf-hosting"
    Type        = "private"
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

# Route Table Association for Public Subnets
resource "aws_route_table_association" "sttf_public_rta_1" {
  subnet_id      = aws_subnet.sttf_public_subnet_1.id
  route_table_id = aws_route_table.sttf_public_rt.id
}

resource "aws_route_table_association" "sttf_public_rta_2" {
  subnet_id      = aws_subnet.sttf_public_subnet_2.id
  route_table_id = aws_route_table.sttf_public_rt.id
}

# NAT Gateway for Private Subnets
resource "aws_eip" "sttf_nat_eip" {
  tags = {
    Name        = "sttf-nat-eip"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

resource "aws_nat_gateway" "sttf_nat_gw" {
  allocation_id = aws_eip.sttf_nat_eip.id
  subnet_id     = aws_subnet.sttf_public_subnet_1.id

  tags = {
    Name        = "sttf-nat-gw"
    Environment = "shared"
    Project     = "sttf-hosting"
  }

  depends_on = [aws_internet_gateway.sttf_igw]
}

# Route Table for Private Subnets
resource "aws_route_table" "sttf_private_rt" {
  vpc_id = aws_vpc.sttf_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sttf_nat_gw.id
  }

  tags = {
    Name        = "sttf-private-rt"
    Environment = "shared"
    Project     = "sttf-hosting"
  }
}

# Route Table Association for Private Subnets
resource "aws_route_table_association" "sttf_private_rta_1" {
  subnet_id      = aws_subnet.sttf_private_subnet_1.id
  route_table_id = aws_route_table.sttf_private_rt.id
}

resource "aws_route_table_association" "sttf_private_rta_2" {
  subnet_id      = aws_subnet.sttf_private_subnet_2.id
  route_table_id = aws_route_table.sttf_private_rt.id
}
