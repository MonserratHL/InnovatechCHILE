# ==========================================
# LAUNCH TEMPLATE - FRONTEND (React + Nginx)
# ==========================================

resource "aws_launch_template" "frontend_template" {
  name_prefix   = "innovatech-frontend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar herramientas necesarias
apt install -y curl wget git awscli docker.io nginx jq

# Iniciar y habilitar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs npm

# Verificar instalaciones
echo "=== Instalaciones ===" >> /var/log/startup.log
node --version >> /var/log/startup.log
npm --version >> /var/log/startup.log
docker --version >> /var/log/startup.log
git --version >> /var/log/startup.log

# Crear carpeta para frontend
mkdir -p /home/ubuntu/frontend/src
cd /home/ubuntu/frontend

# Crear package.json
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

# Crear vite.config.js
cat > vite.config.js << 'VITECFG'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
VITECFG

# Crear index.html
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
    .status h3 { margin-bottom: 10px; color: #333; font-size: 18px; }
    .status p { color: #666; line-height: 1.6; }
    .status code { background: #f5f5f5; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
  </style>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
HTML

# Crear src/main.jsx
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

# Crear src/App.jsx
cat > src/App.jsx << 'JSX'
import { useState, useEffect } from 'react'

function App() {
  const [backendStatus, setBackendStatus] = useState('Verificando...')
  const [dbStatus, setDbStatus] = useState('Verificando...')
  const [instanceInfo, setInstanceInfo] = useState({})

  useEffect(() => {
    // Obtener información de la instancia
    fetch('http://169.254.169.254/latest/meta-data/instance-id')
      .then(r => r.text())
      .then(id => setInstanceInfo(prev => ({ ...prev, frontend_id: id })))
      .catch(e => console.log('Error getting instance ID:', e))

    // Verificar Backend - Usar hostname o IP local
    const backendUrl = window.location.hostname
    const apiUrl = `http://${backendUrl}:8080/api`
    
    console.log('Intentando conectar a Backend en:', apiUrl)
    
    fetch(`${apiUrl}/health`)
      .then(r => r.json())
      .then(data => {
        console.log('Backend response:', data)
        setBackendStatus(`✅ CONECTADO - ${JSON.stringify(data)}`)
      })
      .catch(e => {
        console.error('Backend error:', e)
        setBackendStatus(`❌ NO DISPONIBLE - ${e.message}`)
      })

    fetch(`${apiUrl}/health/db`)
      .then(r => r.json())
      .then(data => {
        console.log('Database response:', data)
        setDbStatus(`✅ CONECTADA - ${JSON.stringify(data)}`)
      })
      .catch(e => {
        console.error('Database error:', e)
        setDbStatus(`❌ NO DISPONIBLE - ${e.message}`)
      })
  }, [])

  return (
    <div className="container">
      <header>
        <h1>🚀 Innovatech Frontend - POC</h1>
        <p>Arquitectura de 3 capas en AWS (Lift & Shift)</p>
        <p style={{fontSize: '12px', color: '#999', marginTop: '10px'}}>Frontend ID: {instanceInfo.frontend_id || 'cargando...'}</p>
      </header>

      <div className="status">
        <h3>✅ Frontend Status</h3>
        <p>Frontend React está corriendo correctamente en Nginx (Puerto 80)</p>
        <p><code>Instancia: t2.micro | Subnet: 10.0.1.0/24 (Pública) | Docker: Instalado</code></p>
      </div>

      <div className={`status ${backendStatus.includes('❌') ? 'error' : ''}`}>
        <h3>🔗 Conectividad Frontend → Backend</h3>
        <p>{backendStatus}</p>
        <p style={{fontSize: '12px', color: '#999', marginTop: '10px'}}>Intentando conectar a: <code>http://{window.location.hostname}:8080/api</code></p>
      </div>

      <div className={`status ${dbStatus.includes('❌') ? 'error' : ''}`}>
        <h3>📊 Conectividad Backend → Database</h3>
        <p>{dbStatus}</p>
      </div>

      <div className="status warning">
        <h3>ℹ️ Detalles de la Arquitectura</h3>
        <p><strong>Frontend:</strong> Subnet Pública 10.0.1.0/24 (Exposada a Internet) - Security Group abierto a HTTP/HTTPS</p>
        <p><strong>Backend:</strong> Subnet Privada 10.0.2.0/24 - Acceso SOLO desde Frontend (Puerto 8080)</p>
        <p><strong>Data:</strong> Subnet Privada 10.0.2.0/24 - Acceso SOLO desde Backend (Puerto 3306)</p>
        <p style={{marginTop: '10px', fontSize: '12px'}}><strong>Principio de Mínimo Privilegio Aplicado:</strong> Cada capa solo accede a la siguiente</p>
      </div>
    </div>
  )
}

export default App
JSX

# Instalar dependencias
chown -R ubuntu:ubuntu /home/ubuntu/frontend
cd /home/ubuntu/frontend
npm install --legacy-peer-deps --verbose

# Buildear React
npm run build

# Configurar Nginx para servir React SPA
cat > /etc/nginx/sites-available/default << 'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /home/ubuntu/frontend/dist;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        # Importante: Servir index.html para rutas SPA
        try_files $uri $uri/ /index.html;
    }

    # Caché para assets estáticos
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Bloquear acceso a archivos de configuración
    location ~ /\. {
        deny all;
    }
}
NGINX

# Restart Nginx
systemctl restart nginx
systemctl enable nginx

echo "=== FRONTEND COMPLETADO EXITOSAMENTE ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-frontend"
      Tier = "Frontend"
      Environment = "POC"
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
  instance_type = var.instance_type
  key_name      = var.key_pair_name

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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar herramientas necesarias
apt install -y curl wget git awscli docker.io jq

# Iniciar y habilitar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Java 17
apt install -y openjdk-17-jdk

# Instalar Maven
apt install -y maven

# Instalar cliente MySQL
apt install -y mysql-client

# Verificar instalaciones
echo "=== Instalaciones ===" >> /var/log/startup.log
java -version >> /var/log/startup.log 2>&1
mvn -version >> /var/log/startup.log
docker --version >> /var/log/startup.log

# IMPORTANTE: Obtener la IP privada de la instancia Data DINÁMICAMENTE
echo "Esperando a que Data esté disponible..." >> /var/log/startup.log
DATA_IP=""
for i in {1..60}; do
  DATA_IP=$(aws ec2 describe-instances \
    --region us-east-1 \
    --filters "Name=tag:Name,Values=innovatech-data" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text 2>/dev/null || echo "")
  
  if [ ! -z "$DATA_IP" ] && [ "$DATA_IP" != "None" ]; then
    echo "Data IP encontrada: $DATA_IP" >> /var/log/startup.log
    break
  fi
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "Intento $i/60 - esperando Data..." >> /var/log/startup.log
  fi
  sleep 1
done

if [ -z "$DATA_IP" ] || [ "$DATA_IP" == "None" ]; then
  echo "ADVERTENCIA: No se pudo obtener IP de Data, usando default 10.0.2.20" >> /var/log/startup.log
  DATA_IP="10.0.2.20"
fi

# Crear carpeta backend
mkdir -p /home/ubuntu/backend/src/main/java/com/innovatech/api
mkdir -p /home/ubuntu/backend/src/main/resources
cd /home/ubuntu/backend

# pom.xml - Corregido
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
    <description>REST API para Innovatech POC - Lift & Shift</description>

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
        <!-- Spring Boot Web (CORREGIDO: spring-boot-starter-web, no webmvc) -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>

        <!-- Spring Boot Data JPA -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>

        <!-- MySQL Driver -->
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-java</artifactId>
            <version>8.0.33</version>
        </dependency>

        <!-- Spring Boot Test -->
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

# application.properties - Usa la IP dinámica de Data
cat > src/main/resources/application.properties << PROPSEOF
server.port=8080
server.servlet.context-path=/api
spring.datasource.url=jdbc:mysql://${DATA_IP}:3306/innovatechdb
spring.datasource.username=innovatech_user
spring.datasource.password=Password123!
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect
logging.level.root=INFO
logging.level.com.innovatech=DEBUG
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
        response.put("message", "Backend Spring Boot API is running");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/db")
    public ResponseEntity<Map<String, Object>> dbHealth() {
        Map<String, Object> response = new HashMap<>();
        try {
            if (jdbcTemplate != null) {
                jdbcTemplate.queryForObject("SELECT 1", Integer.class);
                response.put("status", "OK");
                response.put("database", "MySQL Connected Successfully");
                response.put("timestamp", LocalDateTime.now());
                return ResponseEntity.ok(response);
            } else {
                response.put("status", "WARNING");
                response.put("database", "Database not yet initialized");
                return ResponseEntity.status(503).body(response);
            }
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("database", "MySQL Connection Failed");
            response.put("message", e.getMessage());
            response.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(response);
        }
    }
}
JAVAEOF

# Compilar proyecto
echo "Compilando proyecto Spring Boot..." >> /var/log/startup.log
cd /home/ubuntu/backend
chown -R ubuntu:ubuntu /home/ubuntu/backend
mvn clean package -DskipTests 2>&1 | tee -a /var/log/startup.log

# Verificar que el JAR se creó
if [ -f "target/innovatech-api-1.0.0.jar" ]; then
  echo "✅ JAR compilado exitosamente" >> /var/log/startup.log
else
  echo "❌ Error: JAR no fue creado" >> /var/log/startup.log
  ls -la target/ >> /var/log/startup.log
fi

# Ejecutar Spring Boot
echo "Iniciando Spring Boot en puerto 8080..." >> /var/log/startup.log
nohup java -jar target/innovatech-api-1.0.0.jar > /var/log/backend.log 2>&1 &

sleep 5
echo "=== BACKEND COMPLETADO ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-backend"
      Tier = "Backend"
      Environment = "POC"
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
  instance_type = var.instance_type
  key_name      = var.key_pair_name

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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar MySQL Server
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

# Configurar MySQL para aceptar conexiones desde subnet privada
sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciar MySQL
systemctl restart mysql
systemctl enable mysql

# Verificar MySQL
echo "=== MySQL version ===" >> /var/log/startup.log
mysql --version >> /var/log/startup.log

# Crear base de datos e usuarios con MÍNIMO PRIVILEGIO
echo "Creando base de datos y usuarios..." >> /var/log/startup.log
mysql -u root << 'MYSQLEOF'
CREATE DATABASE IF NOT EXISTS innovatechdb;

-- IMPORTANTE: Crear usuario SOLO para subnet privada (MÍNIMO PRIVILEGIO)
CREATE USER 'innovatech_user'@'10.0.2.%' IDENTIFIED BY 'Password123!';
GRANT ALL PRIVILEGES ON innovatechdb.* TO 'innovatech_user'@'10.0.2.%';
FLUSH PRIVILEGES;

USE innovatechdb;

-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insertar datos de prueba
INSERT INTO users (name, email) VALUES 
  ('Admin Innovatech', 'admin@innovatech.cl'),
  ('Usuario Test', 'test@innovatech.cl');

SHOW DATABASES;
SHOW USERS;
SELECT * FROM users;
MYSQLEOF

echo "=== DATA/MYSQL COMPLETADO EXITOSAMENTE ===" >> /var/log/startup.log
date >> /var/log/startup.log
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "innovatech-data"
      Tier = "Data"
      Environment = "POC"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ==========================================
# INSTANCIAS EC2
# ==========================================

# IMPORTANTE: Data debe crearse PRIMERO
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

# Backend depende de Data
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

# Frontend es pública
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
# ELASTIC IP PARA FRONTEND
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

output "frontend_public_ip" {
  value       = aws_eip.frontend.public_ip
  description = "IP pública del Frontend - Acceso a React"
}

output "frontend_url" {
  value       = "http://${aws_eip.frontend.public_ip}"
  description = "URL para acceder al Frontend - APLICACIÓN PRINCIPAL"
}

output "backend_private_ip" {
  value       = aws_instance.backend.private_ip
  description = "IP privada del Backend"
}

output "data_private_ip" {
  value       = aws_instance.data.private_ip
  description = "IP privada de Data/MySQL"
}

output "frontend_instance_id" {
  value       = aws_instance.frontend.id
  description = "ID de instancia Frontend"
}

output "backend_instance_id" {
  value       = aws_instance.backend.id
  description = "ID de instancia Backend"
}

output "data_instance_id" {
  value       = aws_instance.data.id
  description = "ID de instancia Data"
}

output "ssm_frontend" {
  value       = "aws ssm start-session --target ${aws_instance.frontend.id} --region us-east-1"
  description = "Comando SSH Session Manager - Frontend"
}

output "ssm_backend" {
  value       = "aws ssm start-session --target ${aws_instance.backend.id} --region us-east-1"
  description = "Comando SSH Session Manager - Backend"
}

output "ssm_data" {
  value       = "aws ssm start-session --target ${aws_instance.data.id} --region us-east-1"
  description = "Comando SSH Session Manager - Data"
}
