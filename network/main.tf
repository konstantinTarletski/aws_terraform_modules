terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}
provider "aws" {

}

locals {
  workspace = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  default_tags = merge(var.default_tags, {
    Environment = var.environment
    Workspace   = terraform.workspace
  })
  azs = data.aws_availability_zones.zones.names
}

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = merge(local.default_tags, {
    Name = "VPC-${var.environment}${local.workspace}"
  })
}
#-----------------------------PUBLIC NETWORKS-----------------------------#
resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = merge(local.default_tags, {
    Name = "Internet-GTW-${var.environment}${local.workspace}"
  })
}

resource "aws_subnet" "public_subnets" {
  count                           = length(var.public_subnets_cidrs)
  vpc_id                          = aws_vpc.main_vpc.id
  cidr_block                      = var.public_subnets_cidrs[count.index]
  map_public_ip_on_launch  = true
  availability_zone               = local.azs[count.index % length(local.azs)]
  tags = merge(local.default_tags, {
    Name = "Public-subnet-${var.environment}${local.workspace}-${local.azs[count.index % length(local.azs)]}"
  })
}

resource "aws_route_table" "public_subnet_internet_route" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_internet_gateway.id
  }
  tags = merge(local.default_tags, {
    Name = "Route-table-${var.environment}${local.workspace}"
  })
}

resource "aws_route_table_association" "public_subnet_bind" {
  count          = length(aws_subnet.public_subnets)
  route_table_id = aws_route_table.public_subnet_internet_route.id
  subnet_id      = element(aws_subnet.public_subnets, count.index).id
}
#-----------------------------PRIVATE NETWORKS-----------------------------#

//TODO put NAT in every AZ !!!
resource "aws_eip" "eip_for_nat" {
  domain = "vpc"
  tags = merge(local.default_tags, {
    Name = "Public-subnet-eip-${var.environment}${local.workspace}"
  })
}

resource "aws_nat_gateway" "nat_gw_for_private_subnet" {
  count = 
subnet_id =
}
