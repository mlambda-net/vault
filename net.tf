#devfine the vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "vault vpc"
  }
}

#define the wan gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "vault gateway"
  }
}

# define a eip for nat gateway
resource "aws_eip" "nat_ip" {
  vpc = true
  tags = {
    Name = "vault nat public ip"
  }
}

#define the nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id = aws_subnet.public_subnet.id
  depends_on = [aws_internet_gateway.gateway]
}

#define public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public_cidr
  map_public_ip_on_launch = true
  availability_zone = lookup(var.availability_zone, var.aws_region )
  tags = {
    Name = "vault public subnet"
  }
}

#define public ipsec
resource "aws_security_group" "public_ipsec" {
  name = "public_ipsec"
  description = "vault public subnet ip security"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault public ipsec"
  }

}

#define public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }
  tags = {
    Name = "vault public route table"
  }
}

# Assing the route table to public subnet.
resource "aws_route_table_association" "public_subnet_table" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id = aws_subnet.public_subnet.id
}

#create private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.private_cidr
  availability_zone = lookup(var.availability_zone, var.aws_region)
  tags = {
    Name = "vault private subnet"
  }
}

#define private ipsec
resource "aws_security_group" "private_ipsec" {
  name = "private_ipsec"
  description = "vault private subnet ipsec"
  vpc_id = aws_vpc.vpc.id

  # allow http port connections.
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [aws_subnet.public_subnet.cidr_block]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault private ipsec"
  }
}

# Routing table for private subnet
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "vault private route table"
  }
}

# Assing the private route table as main route table.
resource "aws_main_route_table_association" "main_route" {
  route_table_id = aws_route_table.private_route_table.id
  vpc_id = aws_vpc.vpc.id
}
