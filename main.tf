provider "aws" {
  region     = "us-east-1"
  access_key = "****************"  ##hard coding of accessing key and secret key is not recommended
  secret_key = "*****************"
}
resource "aws_vpc" "myvpc"{

    cidr_block       = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_support =true
    enable_dns_hostnames=true

tags = {
      Name = "Demo-vpc"
    }

}
resource "aws_internet_gateway" "Test-IG" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "Digital-IG"
  }
}
resource "aws_route_table" "Digital-routetable" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Test-IG.id
  }
}
resource "aws_route_table_association" "Demo1" {
  subnet_id      = aws_subnet.digital_subnet.id
  route_table_id = aws_route_table.Digital-routetable.id
}
resource "aws_subnet" "digital_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Demo-digital-subnet"
  }
}
resource "aws_instance" "web" {
  ami             ="ami-0ab4d1e9cf9a1215a"
  instance_type   = "t2.micro"
  associate_public_ip_address =true
  security_groups = [aws_security_group.digital_sg.id]
  subnet_id       = aws_subnet.digital_subnet.id

  #installation of nginx through user data part
  user_data       = <<-EOF
                    #!/bin/bash
                    sudo su
                    amazon-linux-extras
                    sudo amazon-linux-extras install nginx1
                    sudo systemctl start nginx
                    EOF

  tags = {
    Name          = "Digitalserver"
  }
}
resource "aws_security_group" "digital_sg" {
  name            = "Digital-sg"
  description     = "Allow TLS inbound traffic"
  vpc_id          =  aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }


  tags = {
    Name = "digital-sg"
  }
}