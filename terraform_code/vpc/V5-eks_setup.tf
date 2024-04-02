provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  ami             = "ami-080e1f13689e07408"
  instance_type   = "t2.micro"
  key_name        = "key4"
  //security_groups = ["demo-sg"]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  subnet_id       = aws_subnet.dpw-public-subnet-01.id
  for_each        = toset(["jenkins-master", "build-slave", "ansible"])

  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH & Jenkins Access"
  vpc_id      = aws_vpc.dpw-vpc.id
  
  tags = {
    Name = "ssh-port"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "dpw-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "dpw-vpc"
  }
}

resource "aws_subnet" "dpw-public-subnet-01" {
  vpc_id                  = aws_vpc.dpw-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dpw-public-subnet-01"
  }
}

resource "aws_subnet" "dpw-public-subnet-02" {
  vpc_id                  = aws_vpc.dpw-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "dpw-public-subnet-02"
  }
}

resource "aws_internet_gateway" "dpw-igw" {
  vpc_id = aws_vpc.dpw-vpc.id

  tags = {
    Name = "dpw-igw"
  }
}

resource "aws_route_table" "dpw-public-rt" {
  vpc_id = aws_vpc.dpw-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dpw-igw.id
  }

  tags = {
    Name = "dpw-public-rt"
  }
}

resource "aws_route_table_association" "dpw-rta-public-subnet-1" {
  subnet_id      = aws_subnet.dpw-public-subnet-01.id
  route_table_id = aws_route_table.dpw-public-rt.id
}

resource "aws_route_table_association" "dpw-rta-public-subnet-2" {
  subnet_id      = aws_subnet.dpw-public-subnet-02.id
  route_table_id = aws_route_table.dpw-public-rt.id
}

  module "sgs" {
    source = "../sg_eks"
    vpc_id     =     aws_vpc.dpw-vpc.id
 }

  module "eks" {
       source = "../eks"
       vpc_id     =     aws_vpc.dpw-vpc.id
       subnet_ids = [aws_subnet.dpw-public-subnet-01.id,aws_subnet.dpw-public-subnet-02.id]
       sg_ids = module.sgs.security_group_public
 }