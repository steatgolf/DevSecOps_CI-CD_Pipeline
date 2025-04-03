resource "aws_vpc" "main-vpc" {
  cidr_block = "10.255.0.0/16"
}

resource "aws_subnet" "public-subnet-1a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.255.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main-vpc.id
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "routetable" {
  subnet_id      = aws_subnet.public-subnet-1a.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "ssh" {
  name   = "allow-ssh"
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    # Use "0.0.0.0/0" Allow all IP for testing CI/CD #
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["49.228.236.68/32"]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

resource "aws_security_group" "http" {
  name   = "allow-http"
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    # Use "0.0.0.0/0" Allow all IP for testing CI/CD #
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["49.228.236.68/32"]
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }
}

resource "aws_key_pair" "sshkey" {
  key_name   = "aws"
  public_key = file("~/.ssh/aws.pub")

}

resource "aws_eip" "ip1" {
  domain     = "vpc"
  instance   = aws_instance.vm1.id
  # depends_on = [aws_internet_gateway.gateway]
}
