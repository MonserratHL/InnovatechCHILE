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
  availability_zone       = data.aws_availability_zones.available.names[0]
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
  availability_zone = data.aws_availability_zones.available.names[1]

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
# IAM ROLE PARA SESSION MANAGER
# ==========================================

resource "aws_iam_role" "ec2_ssm_role" {
  name = "innovatech-ec2-ssm-role"

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

  tags = {
    Name = "innovatech-ec2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_read_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "innovatech-ec2-profile"
  role = aws_iam_role.ec2_ssm_role.name
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
