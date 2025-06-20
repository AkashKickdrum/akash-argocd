data "aws_availability_zones" "azs" {}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags       = { Name = "vpc-${var.cidr_block}" }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = true
  tags              = { Name = "public-${count.index}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "pub_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
