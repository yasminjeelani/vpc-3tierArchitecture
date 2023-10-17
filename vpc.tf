# Initialize Terraform and AWS provider
provider "aws" {
  region = "us-east-1" # Change to your desired AWS region
}

# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Change to your desired AZ
  map_public_ip_on_launch = true
}

# Create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Change to your desired AZ
}

# Create a security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "RDS security group"
  vpc_id      = aws_vpc.my_vpc.id
}

# Allow incoming traffic to the RDS instance from EC2 instances
resource "aws_security_group_rule" "rds_ingress" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = [aws_subnet.private_subnet.cidr_block]
  security_group_id = aws_security_group.rds_sg.id
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "db_subnet_group"
  }
}

# Create RDS MySQL instance
resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  username             = "myuser"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db-subnet-group.name


  tags = {
    Name = "mydb"
  }
}

# Launch EC2 instances
resource "aws_instance" "public_ec2" {
  ami           = "ami-041feb57c611358bd" # Amazon Linux 2 AMI, change as needed
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "prd01"
  security_groups = [aws_security_group.rds_sg.id] # This will allow the EC2 instance to access the RDS
}

resource "aws_instance" "private_ec2" {
  ami           = "ami-041feb57c611358bd" # Amazon Linux 2 AMI, change as needed
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "prd01"
}

# Output the public and private EC2 instance IPs
output "public_ec2_ip" {
  value = aws_instance.public_ec2.private_ip
}

output "private_ec2_ip" {
  value = aws_instance.private_ec2.private_ip
}

