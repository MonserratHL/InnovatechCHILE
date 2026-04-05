# ==========================================
# LAUNCH TEMPLATE - FRONTEND (React + Nginx)
# ==========================================

resource "aws_launch_template" "frontend_template" {
  name_prefix   = "innovatech-frontend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "spa-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP FRONTEND ===" 
date

# Actualizar sistema
apt update -y
apt upgrade -y

# Instalar herramientas
apt install -y curl wget git docker.io nginx jq

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs npm

echo "=== Instalaciones ===" >> /var/log/startup.log
node --version >> /var/log/startup.log
npm --version >> /var/log/startup.log
docker --version >> /var/log/startup.log

# Crear carpeta frontend
mkdir -p /home/ubuntu/frontend/src
cd /home/ubuntu/frontend

# package.json
cat > package.json << 'PKGJSON'
{
  "name": "innovatech-frontend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^4.3.0"
  }
}
PKGJSON

# vite.config.js
cat > vite.config.js << 'VITECFG'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
VITECFG

# index.html
cat > index.html << 'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Innovatech Frontend - POC</title>
  <style>
    * { margin: 0; padding: 0; }
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
    .container { max-width: 1000px; margin: 0 auto; }
    header { background: white; color: #333; padding: 30px; margin-bottom: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
    header h1 { margin-bottom: 10px; color: #667eea; }
    .status { background: white; padding: 20px; margin: 15px 0; border-radius: 8px; border-left: 5px solid #28a745; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .status.error { border-left-color: #dc3545; }
    .status.warning { border-left-color: #ffc107; }
    .status h3 { margin-bottom: 10px; color: #333; }
    .status p { color: #666; line-height: 1.6; }
    code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
  </style>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
HTML

# src/main.jsx
cat > src/main.jsx << 'JSX'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
JSX

# src/App.jsx
cat > src/App.jsx << 'JSX'
import { useState, useEffect } from 'react'

function App() {
  const [backendStatus, setBackendStatus] = useState('Verificando...')
  const [dbStatus, setDbStatus] = useState('Verificando...')

  useEffect(() => {
    const backendUrl = window.location.hostname
    const apiUrl = `http://${backendUrl}:8080/api`
    
    console.log('Conectando a Backend en:', apiUrl)
    
    fetch(`${apiUrl}/health`)
      .then(r => r.json())
      .then(data => {
        setBackendStatus(`✅ CONECTADO - ${JSON.stringify(data)}`)
      })
      .catch(e => {
        setBackendStatus(`❌ NO DISPONIBLE - ${e.message}`)
      })

    fetch(`${apiUrl}/health/db`)
      .then(r => r.json())
      .then(data => {
        setDbStatus(`✅ CONECTADA - ${JSON.stringify(data)}`)
      })
      .catch(e => {
        setDbStatus(`❌ NO DISPONIBLE - ${e.message}`)
      })
  }, [])

  return (
    <div className="container">
      <header>
        <h1>🚀 Innovatech Frontend - POC</h1>
        <p>Arquitectura de 3 capas en AWS (Lift & Shift)</p>
      </header>

      <div className="status">
        <h3>✅ Frontend Status</h3>
        <p>Frontend React corriendo en Nginx (Puerto 80)</p>
        <p><code>Instancia: t2.micro | Subnet: 10.0.1.0/24 | Docker: Instalado</code></p>
      </div>

      <div className={`status ${backendStatus.includes('❌') ? 'error' : ''}`}>
        <h3>🔗 Conectividad Frontend → Backend</h3>
        <p>{backendStatus}</p>
      </div>

      <div className={`status ${dbStatus.includes('❌') ? 'error' : ''}`}>
        <h3>📊 Conectividad Backend → Database</h3>
        <p>{dbStatus}</p>
      </div>

      <div className="status warning">
        <h3>ℹ️ Arquitectura</h3>
        <p><strong>Frontend:</strong> Subnet Pública 10.0.1.0/24 (Exposada a Internet)</p>
        <p><strong>Backend:</strong> Subnet Privada 10.0.2.0/24 - Acceso solo desde Frontend</p>
        <p><strong>Data:</strong> Subnet Privada 10.0.2.0/24 - Acceso solo desde Backend</p>
        <p style={{marginTop: '10px', fontSize: '12px'}}><strong>Mínimo Privilegio:</strong> Cada capa accede solo a la siguiente</p>
      </div>
    </div>
  )
}

export default App
JSX

# Instalar dependencias
chown -R ubuntu:ubuntu /home/ubuntu/frontend
cd /home/ubuntu/frontend
npm install --legacy-peer-deps

# Build
npm run build

# Configurar Nginx
cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80 default_server;
    root /home/ubuntu/frontend/dist;
    index index.html;

    server_name _;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
NGINX

systemctl restart nginx
systemctl enable nginx

echo "=== FRONTEND COMPLETADO ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-frontend"
      Tier = "Frontend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# LAUNCH TEMPLATE - BACKEND (Spring Boot)
# ==========================================

resource "aws_launch_template" "backend_template" {
  name_prefix   = "innovatech-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "spa-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.backend_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP BACKEND ===" 
date

# Actualizar sistema
apt update -y
apt upgrade -y

# Instalar herramientas
apt install -y curl wget git docker.io jq awscli

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Java 17
apt install -y openjdk-17-jdk

# Instalar Maven
apt install -y maven

# Instalar cliente MySQL
apt install -y mysql-client

echo "=== Instalaciones ===" >> /var/log/startup.log
java -version >> /var/log/startup.log 2>&1
mvn -version >> /var/log/startup.log

# Obtener IP de Data DINÁMICAMENTE
echo "Esperando Data..." >> /var/log/startup.log
DATA_IP=""
for i in {1..60}; do
  DATA_IP=$(aws ec2 describe-instances \
    --region us-east-1 \
    --filters "Name=tag:Name,Values=innovatech-data" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text 2>/dev/null || echo "")
  
  if [ ! -z "$DATA_IP" ] && [ "$DATA_IP" != "None" ]; then
    echo "Data IP: $DATA_IP" >> /var/log/startup.log
    break
  fi
  sleep 1
done

if [ -z "$DATA_IP" ] || [ "$DATA_IP" == "None" ]; then
  DATA_IP="10.0.2.20"
fi

# Crear carpeta backend
mkdir -p /home/ubuntu/backend/src/main/java/com/innovatech/api
mkdir -p /home/ubuntu/backend/src/main/resources
cd /home/ubuntu/backend

# pom.xml - CORREGIDO
cat > pom.xml << 'XMLEOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.innovatech</groupId>
    <artifactId>innovatech-api</artifactId>
    <version>1.0.0</version>
    <packaging>jar</packaging>

    <name>Innovatech API</name>
    <description>REST API para Innovatech POC</description>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.1.0</version>
        <relativePath/>
    </parent>

    <properties>
        <java.version>17</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
XMLEOF

# application.properties - Usa IP dinámica
cat > src/main/resources/application.properties << PROPSEOF
server.port=8080
server.servlet.context-path=/api
spring.datasource.url=jdbc:mysql://${DATA_IP}:3306/innovatechdb
spring.datasource.username=innovatech_user
spring.datasource.password=Password123!
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
logging.level.root=INFO
PROPSEOF

# InnovatechApiApplication.java
cat > src/main/java/com/innovatech/api/InnovatechApiApplication.java << 'JAVAEOF'
package com.innovatech.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@SpringBootApplication
public class InnovatechApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(InnovatechApiApplication.class, args);
    }

    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                    .allowedOrigins("*")
                    .allowedMethods("GET", "POST", "PUT", "DELETE")
                    .allowedHeaders("*");
            }
        };
    }
}
JAVAEOF

# HealthController.java
mkdir -p src/main/java/com/innovatech/api/controller
cat > src/main/java/com/innovatech/api/controller/HealthController.java << 'JAVAEOF'
package com.innovatech.api.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/health")
public class HealthController {

    @Autowired(required = false)
    private JdbcTemplate jdbcTemplate;

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "OK");
        response.put("service", "backend");
        response.put("timestamp", LocalDateTime.now());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/db")
    public ResponseEntity<Map<String, Object>> dbHealth() {
        Map<String, Object> response = new HashMap<>();
        try {
            if (jdbcTemplate != null) {
                jdbcTemplate.queryForObject("SELECT 1", Integer.class);
                response.put("status", "OK");
                response.put("database", "MySQL Connected");
                response.put("timestamp", LocalDateTime.now());
                return ResponseEntity.ok(response);
            } else {
                response.put("status", "ERROR");
                response.put("database", "Database not initialized");
                return ResponseEntity.status(503).body(response);
            }
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", e.getMessage());
            response.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(response);
        }
    }
}
JAVAEOF

# Compilar
cd /home/ubuntu/backend
chown -R ubuntu:ubuntu /home/ubuntu/backend
mvn clean package -DskipTests 2>&1 | tee -a /var/log/startup.log

# Ejecutar
nohup java -jar target/innovatech-api-1.0.0.jar > /var/log/backend.log 2>&1 &

echo "=== BACKEND COMPLETADO ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-backend"
      Tier = "Backend"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# LAUNCH TEMPLATE - DATA (MySQL)
# ==========================================

resource "aws_launch_template" "data_template" {
  name_prefix   = "innovatech-data-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "spa-key"

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.data_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP DATA/MYSQL ===" 
date

# Actualizar sistema
apt update -y
apt upgrade -y

# Instalar MySQL
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

# Configurar MySQL
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart
systemctl restart mysql
systemctl enable mysql

echo "=== MySQL version ===" >> /var/log/startup.log
mysql --version >> /var/log/startup.log

# Crear base de datos con MÍNIMO PRIVILEGIO
mysql -u root << 'MYSQLEOF'
CREATE DATABASE IF NOT EXISTS innovatechdb;
CREATE USER 'innovatech_user'@'10.0.2.%' IDENTIFIED BY 'Password123!';
GRANT ALL PRIVILEGES ON innovatechdb.* TO 'innovatech_user'@'10.0.2.%';
FLUSH PRIVILEGES;

USE innovatechdb;
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES ('Admin Innovatech', 'admin@innovatech.cl');
INSERT INTO users (name, email) VALUES ('Test User', 'test@innovatech.cl');
MYSQLEOF

echo "=== DATA COMPLETADO ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-data"
      Tier = "Data"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# INSTANCIAS EC2
# ==========================================

resource "aws_instance" "data" {
  launch_template {
    id      = aws_launch_template.data_template.id
    version = "$Latest"
  }

  subnet_id = aws_subnet.private.id

  tags = {
    Name = "innovatech-data"
    Tier = "Data"
  }
}

resource "aws_instance" "backend" {
  launch_template {
    id      = aws_launch_template.backend_template.id
    version = "$Latest"
  }

  subnet_id = aws_subnet.private.id

  tags = {
    Name = "innovatech-backend"
    Tier = "Backend"
  }

  depends_on = [aws_instance.data]
}

resource "aws_instance" "frontend" {
  launch_template {
    id      = aws_launch_template.frontend_template.id
    version = "$Latest"
  }

  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "innovatech-frontend"
    Tier = "Frontend"
  }

  depends_on = [aws_internet_gateway.main, aws_instance.backend]
}

# ==========================================
# ELASTIC IP
# ==========================================

resource "aws_eip" "frontend" {
  instance = aws_instance.frontend.id
  domain   = "vpc"

  tags = {
    Name = "innovatech-frontend-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# OUTPUTS
# ==========================================

output "frontend_url" {
  value       = "http://${aws_eip.frontend.public_ip}"
  description = "URL Frontend - APLICACIÓN PRINCIPAL"
}

output "frontend_public_ip" {
  value       = aws_eip.frontend.public_ip
  description = "IP pública Frontend"
}

output "backend_private_ip" {
  value       = aws_instance.backend.private_ip
  description = "IP privada Backend"
}

output "data_private_ip" {
  value       = aws_instance.data.private_ip
  description = "IP privada Data"
}

output "frontend_id" {
  value = aws_instance.frontend.id
}

output "backend_id" {
  value = aws_instance.backend.id
}

output "data_id" {
  value = aws_instance.data.id
}

output "ssm_frontend" {
  value = "aws ssm start-session --target ${aws_instance.frontend.id} --region us-east-1"
}

output "ssm_backend" {
  value = "aws ssm start-session --target ${aws_instance.backend.id} --region us-east-1"
}

output "ssm_data" {
  value = "aws ssm start-session --target ${aws_instance.data.id} --region us-east-1"
}
