resource "aws_vpc" "main-vpc" {
  cidr_block           = "10.255.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public-zone1" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.255.1.0/24"
  availability_zone = local.zone1

  tags = {
    "Name" = "${local.env}-public-${local.zone1}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main-vpc.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
}

resource "aws_route_table_association" "routetable" {
  subnet_id      = aws_subnet.public-zone1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "http" {
  name   = "allow-http"
  vpc_id = aws_vpc.main-vpc.id

  ingress {
    # Use "0.0.0.0/0" Allow all IP for testing CI/CD #
    cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = ["49.228.237.125/32"]
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

## Uncomment aws_security_group.ssh and aws_key_pair to enable SSH access for deployment instead of using SSM ##

# resource "aws_security_group" "ssh" {
#   name   = "allow-ssh"
#   vpc_id = aws_vpc.main-vpc.id

#   ingress {
#     # Use "0.0.0.0/0" Allow all IP for testing CI/CD #
#     cidr_blocks = ["0.0.0.0/0"]
#     # cidr_blocks = ["49.228.237.125/32"]
#     from_port = 22
#     to_port   = 22
#     protocol  = "tcp"
#   }

#   egress {
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#   }
# }


# resource "aws_key_pair" "sshkey" {
#   key_name   = "aws"
#   public_key = file("~/.ssh/aws.pub")

# }


# resource "aws_eip" "nat" {
#   domain = "vpc"

#   tags = {
#     Name = "${local.env}-nat"
#   }
# }

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public-zone1.id

#   tags = {
#     Name = "${local.env}-nat"
#   }

#   depends_on = [aws_internet_gateway.gateway]
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }

#   tags = {
#     Name = "${local.env}-private"
#   }
# }