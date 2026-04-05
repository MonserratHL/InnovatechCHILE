# ==========================================
# SECURITY GROUP - FRONTEND (React)
# ==========================================

resource "aws_security_group" "frontend_sg" {
  name        = "innovatech-frontend-sg"
  description = "Frontend pública con React - Expuesta a Internet"
  vpc_id      = aws_vpc.innovatech.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from Internet"
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from Internet"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from Internet"
  }

  # Egress - HTTP/HTTPS para actualizaciones
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for updates"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for updates"
  }

  # Egress - DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  # Egress - Backend API (puerto 8080) - SOLO a subnet privada
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
    description = "API calls to Backend"
  }

  tags = {
    Name = "innovatech-frontend-sg"
  }
}

# ==========================================
# SECURITY GROUP - BACKEND (Spring Boot API)
# ==========================================

resource "aws_security_group" "backend_sg" {
  name        = "innovatech-backend-sg"
  description = "Backend privado con Spring Boot - Acceso SOLO desde Frontend"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC (para Session Manager)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  # Spring Boot API (8080) SOLO desde Frontend
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    description     = "API from Frontend only"
  }

  # Egress - MySQL a Data (3306) SOLO a backend sg
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.data_sg.id]
    description     = "MySQL to Data tier"
  }

  # Egress - HTTP/HTTPS para actualizaciones
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for updates"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for updates"
  }

  # Egress - DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "innovatech-backend-sg"
  }
}

# ==========================================
# SECURITY GROUP - DATA (MySQL)
# ==========================================

resource "aws_security_group" "data_sg" {
  name        = "innovatech-data-sg"
  description = "Data privada con MySQL - Acceso SOLO desde Backend"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC (para Session Manager)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  # MySQL (3306) SOLO desde Backend - MÍNIMO PRIVILEGIO
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
    description     = "MySQL from Backend only"
  }

  # Egress - HTTP/HTTPS para actualizaciones
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for updates"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for updates"
  }

  # Egress - DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  tags = {
    Name = "innovatech-data-sg"
  }
}

# ==========================================
# OUTPUTS
# ==========================================

output "frontend_sg_id" {
  value = aws_security_group.frontend_sg.id
}

output "backend_sg_id" {
  value = aws_security_group.backend_sg.id
}

output "data_sg_id" {
  value = aws_security_group.data_sg.id
}
