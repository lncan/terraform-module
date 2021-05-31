# Local values

locals {
  nat_gateway_count = var.single_nat_gateway ? 1 : length(var.private_cidr_block)
}

##############
#VPC settings#
##############

# VPC
resource "aws_vpc" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  cidr_block              = var.vpc_cidr_block
  instance_tenancy        = "default"
  enable_dns_support      = "true"
  enable_dns_hostnames    = "true"
  enable_classiclink      = "false"
  tags                    = var.vpc_tag
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  count                   = var.create_vpc && length(var.public_cidr_block) > 0 ? length(var.public_cidr_block) : 0
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = var.public_cidr_block[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = "true"
  tags                    = var.public_subnet_tag[count.index]
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  count                   = var.create_vpc && length(var.private_cidr_block) > 0 ? length(var.private_cidr_block) : 0
  vpc_id                  = aws_vpc.vpc[0].id
  cidr_block              = var.private_cidr_block[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = "false"
  tags                    = var.private_subnet_tag[count.index]
}

# Internet GW
resource "aws_internet_gateway" "internet_gateway" {
  count  = var.create_vpc && length(var.public_cidr_block) > 0 ? 1 : 0
  vpc_id = aws_vpc.vpc[0].id
  tags   = var.internet_gateway_tag
}

# Public route tables
resource "aws_route_table" "public_route_table" {
  count        = var.create_vpc && length(var.public_cidr_block) > 0 ? 1 : 0
  vpc_id       = aws_vpc.vpc[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway[0].id
  }
  tags   = var.public_rtb_tag
}

# Publics route associations
resource "aws_route_table_association" "public_association" {
  count          = var.create_vpc && length(var.public_cidr_block) > 0 ? length(var.public_cidr_block) : 0
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table[0].id
}

# ##############
# #NAT settings#
# ##############

# AWS EIP 
resource "aws_eip" "nat" {
  count                   = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  vpc                     = true
}

# Nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  count                   = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  allocation_id           = element(aws_eip.nat.*.id, var.single_nat_gateway ? 0 : count.index)
  subnet_id               = element(aws_subnet.public_subnet.*.id, var.single_nat_gateway ? 0 : count.index)
  depends_on              = [aws_internet_gateway.internet_gateway]
}

# Private route tables
resource "aws_route_table" "private_route_table" {
  count        = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  vpc_id       = aws_vpc.vpc[0].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.nat_gateway.*.id, var.single_nat_gateway ? 0 : count.index)
  }
  tags   = var.private_rtb_tag[count.index]
}

# Private route associations
resource "aws_route_table_association" "private_association" {
  count                   = var.create_vpc && var.enable_nat_gateway ? length(var.private_cidr_block) : 0
  subnet_id               = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id          = element(aws_route_table.private_route_table.*.id, var.single_nat_gateway ? 0 : count.index)
}