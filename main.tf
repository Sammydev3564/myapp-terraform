#configure aws provider
provider "aws" {
  region = "us-east-1"
}

#create variables
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key" {}

#create vpc
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}
#create public subnet
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

#create route table
#resource "aws_route_table" "myapp-route-table" {
# vpc_id =aws_vpc.myapp-vpc.id

#route {
#  cidr_block = "0.0.0.0/0"
#  gateway_id = aws_internet_gateway.myapp-igw.id  }
#tags = {
#  Name = "${var.env_prefix}-rtb"}
#}

#create internet gateway
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw"
  }
}
#associate the route table
#resource "aws_route_table_association" "ass-rtb" {
# subnet_id      = aws_subnet.myapp-subnet-1.id
# route_table_id = aws_route_table.myapp-route-table.id
#}
#c
resource "aws_default_route_table" "myapp-route-table" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }

  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}
resource "aws_security_group" "myapp-sg" {
  name        = "myapp-sg"
  description = "allow ssh"
  vpc_id      = aws_vpc.myapp-vpc.id

  ingress {
    from_port        = "22"
    to_port          = "22"
    protocol         = "tcp"
    cidr_blocks      = [var.my_ip]
  }
ingress {
    from_port        = "8080"
    to_port          = "8080"
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }

}

data "aws_ami" "myapp-server" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] # Canonical official
}
  
  resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.myapp-server.id 

  instance_type = var.instance_type
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone
  associate_public_ip_address = true
   key_name = aws_key_pair.ssh-key.key_name
tags = {
    Name = "${var.env_prefix}-websever"}
}
  
resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key =var.public_key

}