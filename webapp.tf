provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name      = "prd01"

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "Hello, World!" > /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server"
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
}
