# ==========================================
# SECURITY GROUP - FRONTEND (React + Nginx)
# ==========================================

resource "aws_security_group" "frontend_sg" {
  name        = "innovatech-frontend-sg"
  description = "Frontend pública con React/Nginx - expuesta a Internet"
  vpc_id      = aws_vpc.innovatech.id

  # HTTP - Acceso desde Internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from Internet"
  }

  # HTTPS - Acceso desde Internet
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from Internet"
  }

  # SSH - Acceso administrativo (AWS Session Manager)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH for administration"
  }

  # Egress - HTTPS para actualizaciones de paquetes
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
  }

  # Egress - HTTP para actualizaciones de paquetes
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
  }

  # Egress - DNS
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS queries"
  }

  # Egress - Backend API (puerto 8080) IMPORTANTE: Solo a subnet privada
  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
    description = "API calls to Backend Spring Boot"
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
  description = "Backend privado con Spring Boot - acceso solo desde Frontend"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC (para Session Manager)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC (Session Manager)"
  }

  # Spring Boot API (8080) SOLO desde Frontend
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    description     = "Spring Boot REST API from Frontend only"
  }

  # Egress - MySQL a Data (puerto 3306) SOLO a subnet privada
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.data_sg.id]
    description     = "MySQL to Data tier only"
  }

  # Egress - HTTPS para actualizaciones
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
  }

  # Egress - HTTP para actualizaciones
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
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
  description = "Data privada con MySQL - acceso solo desde Backend"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC (para Session Manager)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC (Session Manager)"
  }

  # MySQL (3306) SOLO desde Backend
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
    description     = "MySQL from Backend only - MÍNIMO PRIVILEGIO"
  }

  # Egress - HTTPS para actualizaciones
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
  }

  # Egress - HTTP para actualizaciones
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for package updates"
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
