# 1. Membuat VPC Utama
resource "aws_vpc" "lks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "LKS-VPC"
  }
}

# 2. Membuat Internet Gateway (Agar Public Subnet punya akses internet)
resource "aws_internet_gateway" "lks_igw" {
  vpc_id = aws_vpc.lks_vpc.id

  tags = {
    Name = "LKS-IGW"
  }
}

# 3. Membuat Public Subnet 1 (Untuk Load Balancer di AZ a)
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "LKS-Public-Subnet-1"
  }
}

# 4. Membuat Private Subnet 1 (Untuk Server EC2 App di AZ a)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "LKS-Private-Subnet-1"
  }
}

# 5. Membuat Route Table untuk Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.lks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lks_igw.id
  }

  tags = {
    Name = "LKS-Public-RouteTable"
  }
}

# 6. Menghubungkan Public Subnet 1 ke Route Table Public
resource "aws_route_table_association" "public_1_assoc" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
  } 

# 7. Membuat Public Subnet 2 (Cadangan Load Balancer di AZ b)
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "LKS-Public-Subnet-2"
  }
}

# 8. Membuat Private Subnet 2 (Cadangan Server EC2 di AZ b)
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.lks_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "LKS-Private-Subnet-2"
  }
}

# 9. Menghubungkan Public Subnet 2 ke Route Table Public
resource "aws_route_table_association" "public_2_assoc" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
}  