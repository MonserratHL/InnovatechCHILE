# ==========================================
# SECURITY GROUP - FRONTEND (React)
# ==========================================

resource "aws_security_group" "frontend_sg" {
  name        = "innovatech-frontend-sg"
  description = "Frontend pública con React"
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

  # SSH - Acceso administrativo
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from Internet"
  }

  # Egress - Llamadas a Backend API (puerto 8080 - Spring Boot default)
  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
    description     = "API calls to Backend Spring Boot"
  }

  # Egress - HTTPS para actualizaciones
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
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
  description = "Backend privado con Spring Boot REST API"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  # Spring Boot API desde Frontend (puerto 8080)
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
    description     = "Spring Boot REST API from Frontend"
  }

  # Egress - MySQL a Data (puerto 3306)
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.data_sg.id]
    description     = "MySQL to Data tier"
  }

  # Egress - HTTPS para actualizaciones
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
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
  description = "Data privada con MySQL"
  vpc_id      = aws_vpc.innovatech.id

  # SSH desde VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "SSH from VPC"
  }

  # MySQL solo desde Backend
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
    description     = "MySQL from Backend Spring Boot"
  }

  # Egress - HTTPS para actualizaciones
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for package updates"
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
