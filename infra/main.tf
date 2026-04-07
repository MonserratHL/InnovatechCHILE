# ==========================================
# VPC PRINCIPAL (10.0.0.0/16)
# ==========================================

resource "aws_vpc" "innovatech" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "innovatech-vpc"
  }
}

# ==========================================
# INTERNET GATEWAY
# ==========================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.innovatech.id

  tags = {
    Name = "innovatech-igw"
  }
}

# ==========================================
# SUBNET PÚBLICA (Frontend React)
# ==========================================

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.innovatech.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "innovatech-public-subnet"
  }
}

# ==========================================
# SUBNET PRIVADA (Backend + Data)
# ==========================================

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.innovatech.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "innovatech-private-subnet"
  }
}

# ==========================================
# ROUTE TABLE PÚBLICA
# ==========================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.innovatech.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "innovatech-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ==========================================
# ROUTE TABLE PRIVADA
# ==========================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.innovatech.id

  tags = {
    Name = "innovatech-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


# ==========================================
# ELASTIC IP PARA NAT GATEWAY
# ==========================================

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "innovatech-nat-eip"
  }
}

# ==========================================
# NAT GATEWAY
# ==========================================

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "innovatech-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# ROUTE PRIVADA HACIA NAT GATEWAY
# ==========================================

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}


# ==========================================
# OUTPUTS
# ==========================================

output "vpc_id" {
  value = aws_vpc.innovatech.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}
