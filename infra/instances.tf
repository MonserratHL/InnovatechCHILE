# ==========================================
# LAUNCH TEMPLATE - FRONTEND (React + Nginx)
# ==========================================

resource "aws_launch_template" "frontend_template" {
  name_prefix   = "innovatech-frontend-"
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP FRONTEND SIMPLIFICADO ===" 
date

apt update -y
apt install -y nginx

apt update -y
apt install -y nginx docker.io docker-compose

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Carpeta futura para contenedor React
mkdir -p /home/ubuntu/docker/frontend

echo "=== Nginx instalado ===" >> /var/log/startup.log
nginx -v >> /var/log/startup.log 2>&1

mkdir -p /var/www/html

cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Innovatech Frontend - POC</title>
  <style>
    body { 
      font-family: Arial, sans-serif; 
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
      color: white; 
      text-align: center; 
      padding: 50px; 
      margin: 0;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
    }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { font-size: 3em; margin-bottom: 20px; }
    .status { 
      background: rgba(255,255,255,0.1); 
      padding: 20px; 
      border-radius: 10px; 
      margin: 20px 0;
      border: 2px solid #28a745;
    }
    .error { border-color: #dc3545; }
    .warning { border-color: #ffc107; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 Innovatech Frontend - POC</h1>
    <p>Arquitectura de 3 capas en AWS (Lift & Shift)</p>
    
    <div class="status">
      <h2>✅ Frontend Status</h2>
      <p>Frontend básico funcionando en Nginx (Puerto 80)</p>
      <p><strong>Instancia:</strong> t2.micro | <strong>Subnet:</strong> 10.0.1.0/24</p>
      <p><strong>IP:</strong> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
    </div>

    <div class="status warning">
      <h2>🔄 Próximos Pasos</h2>
      <p>Este es un frontend simplificado para verificar conectividad</p>
      <p>Si ves esta página, Nginx funciona correctamente</p>
      <p>El siguiente paso es implementar React completo</p>
    </div>

    <div class="status">
      <h2>ℹ️ Arquitectura</h2>
      <p><strong>Frontend:</strong> Subnet Pública 10.0.1.0/24 (Expuesta a Internet)</p>
      <p><strong>Backend:</strong> Subnet Privada 10.0.2.0/24 - Acceso solo desde Frontend</p>
      <p><strong>Data:</strong> Subnet Privada 10.0.2.0/24 - Acceso solo desde Backend</p>
    </div>
  </div>
</body>
</html>
HTML

chown -R www-data:www-data /var/www/html
chmod 755 /var/www/html
chmod 644 /var/www/html/index.html

cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html;
    
    server_name _;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX

systemctl start nginx
systemctl enable nginx

echo "=== Nginx status ===" >> /var/log/startup.log
systemctl status nginx --no-pager >> /var/log/startup.log 2>&1

echo "=== FRONTEND SIMPLIFICADO COMPLETADO ===" >> /var/log/startup.log
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
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP BACKEND ===" 
date

apt update -y
apt upgrade -y
apt install -y curl wget git docker.io jq

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Carpeta futura contenedor Spring Boot
mkdir -p /home/ubuntu/docker/backend

apt install -y openjdk-17-jdk
apt install -y maven
apt install -y mysql-client

echo "=== Instalaciones ===" >> /var/log/startup.log
java -version >> /var/log/startup.log 2>&1
mvn -version >> /var/log/startup.log

DATA_IP="10.0.2.20"
echo "Data IP configurada: $DATA_IP" >> /var/log/startup.log

mkdir -p /home/ubuntu/backend/src/main/java/com/innovatech/api
mkdir -p /home/ubuntu/backend/src/main/resources
cd /home/ubuntu/backend

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

cat > src/main/resources/application.properties << PROPSEOF
server.port=8080
server.servlet.context-path=/api
spring.datasource.url=jdbc:mysql://$${DATA_IP}:3306/innovatechdb
spring.datasource.username=innovatech_user
spring.datasource.password=Password123!
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
logging.level.root=INFO
PROPSEOF

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

cd /home/ubuntu/backend
chown -R ubuntu:ubuntu /home/ubuntu/backend
mvn clean package -DskipTests 2>&1 | tee -a /var/log/startup.log

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
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name      = "spa-key"

  user_data = base64encode(<<-EOF
#!/bin/bash
set -e
exec > /var/log/startup.log 2>&1
echo "=== INICIANDO SETUP DATA/MYSQL ===" 
date

apt update -y
apt upgrade -y

DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

systemctl restart mysql
systemctl enable mysql

usermod -aG docker ubuntu

# Carpeta futura contenedor MySQL con volumen persistente
mkdir -p /home/ubuntu/docker/mysql

echo "=== MySQL version ===" >> /var/log/startup.log
mysql --version >> /var/log/startup.log

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

  subnet_id              = aws_subnet.private.id
  private_ip            = "10.0.2.20"
  vpc_security_group_ids = [aws_security_group.data_sg.id]

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

  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]

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

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

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
