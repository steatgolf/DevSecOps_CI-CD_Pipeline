resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main-vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public-subnet-1a.id]
  security_group_ids  = [aws_security_group.vpc_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main-vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.public-subnet-1a.id]
  security_group_ids  = [aws_security_group.vpc_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main-vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
#   route_table_ids   = [aws_route_table.routetable.ids]

}
resource "aws_security_group" "vpc_sg" {
  name        = "ecr-vpc-endpoint-sg"
  description = "Allow EC2 to access ECR VPC endpoints"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.255.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
