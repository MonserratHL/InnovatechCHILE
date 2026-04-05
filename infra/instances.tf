# ==========================================
# LAUNCH TEMPLATE - FRONTEND (React)
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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar Docker
apt install -y docker.io

# Instalar Git
apt install -y git

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Node.js (para React build tools como Vite/Webpack)
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs npm

# Verificar instalaciones en logs
echo "=== Docker version ===" >> /var/log/startup.log
docker --version >> /var/log/startup.log

echo "=== Git version ===" >> /var/log/startup.log
git --version >> /var/log/startup.log

echo "=== Node version ===" >> /var/log/startup.log
node --version >> /var/log/startup.log

echo "=== npm version ===" >> /var/log/startup.log
npm --version >> /var/log/startup.log

# Crear aplicación React simple
mkdir -p /home/ubuntu/frontend
cat > /home/ubuntu/frontend/package.json << 'JSON'
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
JSON

# Crear estructura React simple
mkdir -p /home/ubuntu/frontend/src
cat > /home/ubuntu/frontend/vite.config.js << 'JS'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 80
  }
})
JS

cat > /home/ubuntu/frontend/index.html << 'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Innovatech Frontend - React POC</title>
  <style>
    * { margin: 0; padding: 0; }
    body { font-family: Arial, sans-serif; background: #f5f5f5; }
    .container { max-width: 1000px; margin: 0 auto; padding: 20px; }
    header { background: #007bff; color: white; padding: 20px; margin-bottom: 20px; border-radius: 5px; }
    .status { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #28a745; }
    .status.error { border-left-color: #dc3545; }
    .status h3 { margin-bottom: 10px; }
    .status p { color: #666; }
    .api-response { background: #f9f9f9; padding: 10px; border-radius: 3px; font-family: monospace; font-size: 12px; }
  </style>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
HTML

cat > /home/ubuntu/frontend/src/main.jsx << 'JSX'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
JSX

cat > /home/ubuntu/frontend/src/App.jsx << 'JSX'
import { useState, useEffect } from 'react'

function App() {
  const [backendStatus, setBackendStatus] = useState('Verificando...')
  const [dbStatus, setDbStatus] = useState('Verificando...')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Verificar Backend Spring Boot API Health
    fetch('http://10.0.2.10:8080/api/health')
      .then(r => r.json())
      .then(data => {
        setBackendStatus(`✅ Backend conectado: ${JSON.stringify(data)}`)
      })
      .catch(e => {
        setBackendStatus(`❌ Backend no disponible: ${e.message}`)
      })

    // Verificar Database Health
    fetch('http://10.0.2.10:8080/api/db-health')
      .then(r => r.json())
      .then(data => {
        setDbStatus(`✅ Base de datos conectada: ${JSON.stringify(data)}`)
      })
      .catch(e => {
        setDbStatus(`❌ Base de datos no disponible: ${e.message}`)
      })

    setLoading(false)
  }, [])

  return (
    <div className="container">
      <header>
        <h1>🚀 Innovatech Frontend - POC React</h1>
        <p>Arquitectura de 3 capas en AWS con Spring Boot</p>
      </header>

      <div className="status">
        <h3>Frontend Status</h3>
        <p>✅ Frontend React está corriendo correctamente</p>
      </div>

      <div className={`status ${backendStatus.includes('❌') ? 'error' : ''}`}>
        <h3>Backend Spring Boot API</h3>
        <p>{loading ? 'Cargando...' : backendStatus}</p>
      </div>

      <div className={`status ${dbStatus.includes('❌') ? 'error' : ''}`}>
        <h3>Database Connection</h3>
        <p>{loading ? 'Cargando...' : dbStatus}</p>
      </div>
    </div>
  )
}

export default App
JSX

# Instalar dependencias
chown -R ubuntu:ubuntu /home/ubuntu/frontend
cd /home/ubuntu/frontend
npm install

# Hacer build de React
npm run build

# Instalar http-server para servir los archivos estáticos
npm install -g http-server

# Servir la carpeta dist en puerto 80
nohup npx http-server /home/ubuntu/frontend/dist -p 80 > /var/log/frontend.log 2>&1 &

echo "Frontend React iniciado correctamente en puerto 80" >> /var/log/startup.log
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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar Docker
apt install -y docker.io

# Instalar Git
apt install -y git

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instalar Java 17 (requerido por Spring Boot)
apt install -y openjdk-17-jdk

# Instalar Maven (para construir Spring Boot)
apt install -y maven

# Instalar cliente MySQL
apt install -y mysql-client

# Verificar instalaciones en logs
echo "=== Docker version ===" >> /var/log/startup.log
docker --version >> /var/log/startup.log

echo "=== Git version ===" >> /var/log/startup.log
git --version >> /var/log/startup.log

echo "=== Java version ===" >> /var/log/startup.log
java -version >> /var/log/startup.log 2>&1

echo "=== Maven version ===" >> /var/log/startup.log
mvn -version >> /var/log/startup.log

# Crear aplicación Spring Boot
mkdir -p /home/ubuntu/backend
cd /home/ubuntu/backend

# Crear estructura del proyecto Spring Boot
mkdir -p src/main/java/com/innovatech/api
mkdir -p src/main/resources

# pom.xml - Configuración Maven y dependencias
cat > /home/ubuntu/backend/pom.xml << 'XML'
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
        <!-- Spring Boot Web Starter -->
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

        <!-- Lombok (Optional - para reducir código) -->
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
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
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
XML

# application.properties - Configuración Spring Boot
cat > /home/ubuntu/backend/src/main/resources/application.properties << 'PROPS'
# Server Configuration
server.port=8080
server.servlet.context-path=/api

# Database Configuration
spring.datasource.url=jdbc:mysql://10.0.2.20:3306/innovatechdb
spring.datasource.username=innovatech_user
spring.datasource.password=Password123!
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# JPA Configuration
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=false
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQL8Dialect

# Logging
logging.level.root=INFO
logging.level.com.innovatech=DEBUG
PROPS

# Clase principal Spring Boot Application
cat > /home/ubuntu/backend/src/main/java/com/innovatech/api/InnovatechApiApplication.java << 'JAVA'
package com.innovatech.api;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class InnovatechApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(InnovatechApiApplication.class, args);
    }
}
JAVA

# Health Controller
cat > /home/ubuntu/backend/src/main/java/com/innovatech/api/controller/HealthController.java << 'JAVA'
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

    @Autowired
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
            jdbcTemplate.queryForObject("SELECT 1", Integer.class);
            response.put("status", "OK");
            response.put("database", "MySQL Connected");
            response.put("timestamp", LocalDateTime.now());
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERROR");
            response.put("message", "Database connection failed: " + e.getMessage());
            response.put("timestamp", LocalDateTime.now());
            return ResponseEntity.status(500).body(response);
        }
    }
}
JAVA

# User Entity
cat > /home/ubuntu/backend/src/main/java/com/innovatech/api/model/User.java << 'JAVA'
package com.innovatech.api.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(length = 100)
    private String name;

    @Column(length = 100)
    private String email;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    public User() {
        this.createdAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
JAVA

# User Repository
cat > /home/ubuntu/backend/src/main/java/com/innovatech/api/repository/UserRepository.java << 'JAVA'
package com.innovatech.api.repository;

import com.innovatech.api.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
}
JAVA

# User Controller
cat > /home/ubuntu/backend/src/main/java/com/innovatech/api/controller/UserController.java << 'JAVA'
package com.innovatech.api.controller;

import com.innovatech.api.model.User;
import com.innovatech.api.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/users")
@CrossOrigin(origins = "*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        return ResponseEntity.ok(userRepository.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return userRepository.findById(id)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<User> createUser(@RequestBody User user) {
        User saved = userRepository.save(user);
        return ResponseEntity.ok(saved);
    }
}
JAVA

# Compilar y empaquetar
cd /home/ubuntu/backend
chown -R ubuntu:ubuntu /home/ubuntu/backend
mvn clean package -DskipTests

# Ejecutar Spring Boot
nohup java -jar /home/ubuntu/backend/target/innovatech-api-1.0.0.jar > /var/log/backend.log 2>&1 &

echo "Backend Spring Boot iniciado correctamente en puerto 8080" >> /var/log/startup.log
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

# Actualizar sistema y aplicar parches de seguridad
apt update -y
apt upgrade -y

# Instalar MySQL Server
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

# Configurar MySQL para conexiones remotas
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciar y habilitar MySQL
systemctl restart mysql
systemctl enable mysql

# Verificar instalación en logs
echo "=== MySQL version ===" >> /var/log/startup.log
mysql --version >> /var/log/startup.log

# Crear base de datos e inicializar
mysql -u root << 'MYSQL'
CREATE DATABASE IF NOT EXISTS innovatechdb;
CREATE USER 'innovatech_user'@'%' IDENTIFIED BY 'Password123!';
GRANT ALL PRIVILEGES ON innovatechdb.* TO 'innovatech_user'@'%';
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
MYSQL

echo "Data tier (MySQL) iniciado correctamente" >> /var/log/startup.log
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
# INSTANCIA FRONTEND (PÚBLICA)
# ==========================================

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

  depends_on = [aws_internet_gateway.main]
}

# ==========================================
# INSTANCIA BACKEND (PRIVADA)
# ==========================================

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

# ==========================================
# INSTANCIA DATA (PRIVADA)
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

output "public_ip" {
  value       = aws_eip.frontend.public_ip
  description = "IP pública del Frontend"
}

output "frontend_url" {
  value       = "http://${aws_eip.frontend.public_ip}"
  description = "URL para acceder al Frontend React"
}

output "backend_api_url" {
  value       = "http://10.0.2.10:8080/api"
  description = "URL de la API REST Spring Boot (interna)"
}

output "frontend_instance_id" {
  value       = aws_instance.frontend.id
  description = "ID instancia Frontend"
}

output "backend_instance_id" {
  value       = aws_instance.backend.id
  description = "ID instancia Backend"
}

output "data_instance_id" {
  value       = aws_instance.data.id
  description = "ID instancia Data"
}

output "backend_private_ip" {
  value       = aws_instance.backend.private_ip
  description = "IP privada Backend (para conectar desde Frontend)"
}

output "data_private_ip" {
  value       = aws_instance.data.private_ip
  description = "IP privada Data (para conectar desde Backend)"
}

output "ssm_session_frontend" {
  value       = "aws ssm start-session --target ${aws_instance.frontend.id}"
  description = "Comando para conectar a Frontend vía Session Manager"
}

output "ssm_session_backend" {
  value       = "aws ssm start-session --target ${aws_instance.backend.id}"
  description = "Comando para conectar a Backend vía Session Manager"
}

output "ssm_session_data" {
  value       = "aws ssm start-session --target ${aws_instance.data.id}"
  description = "Comando para conectar a Data vía Session Manager"
}
