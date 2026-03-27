resource "aws_instance" "spa_server" {
  ami = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  key_name = "spa-key"

  security_groups = [ aws_security_group.web_sg.name ]

  user_data = <<-EOF
                #!/bin/bash
                apt update -y
                apt install nginx -y
                systemctl start nginx
                systemctl enable nginx
                EOF
    tags = {
      Name = "spa-frontend"
    }
}