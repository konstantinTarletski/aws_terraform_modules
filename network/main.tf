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
  public_subnets_by_az = {
    for az in distinct([
      for s in aws_subnet.public_subnets : s.availability_zone
    ]) :
    az => [
      for s in aws_subnet.public_subnets :
      {
        id   = s.id
        cidr = s.cidr_block
      }
      if s.availability_zone == az
    ]
  }
  private_subnets_by_az = {
    for az in distinct([
      for s in aws_subnet.private_subnets : s.availability_zone
    ]) :
    az => [
      for s in aws_subnet.private_subnets :
      {
        id   = s.id
        cidr = s.cidr_block
      }
      if s.availability_zone == az
    ]
  }
  db_subnets_by_az = {
    for az in distinct([
      for s in aws_subnet.db_subnets : s.availability_zone
    ]) :
    az => [
      for s in aws_subnet.db_subnets :
      {
        id   = s.id
        cidr = s.cidr_block
      }
      if s.availability_zone == az
    ]
  }

  //finding same AZ for private and public subnets
  public_and_private_subnets_same_zones = setintersection(keys(local.public_subnets_by_az), keys(local.private_subnets_by_az))
  //finding final AZ for NATs
  nat_zones = length(aws_subnet.private_subnets) > 0 ? (
    length(local.public_and_private_subnets_same_zones) > 0 ? local.public_and_private_subnets_same_zones : (
      length(local.public_subnets_by_az) > 0 ? [keys(local.public_subnets_by_az)[0]] : []
    )
  ) : []

  //finding subnets for NATs
  nat_gateways_zones_and_subnets = {
    for zone in local.nat_zones :
    zone => {
      subnet_id = local.public_subnets_by_az[zone][0].id
    }
  }
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
  count                   = length(var.public_subnets_cidrs)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnets_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index % length(local.azs)]
  tags = merge(local.default_tags, {
    Name = "Public-subnet-${var.environment}${local.workspace}-${local.azs[count.index % length(local.azs)]}"
  })
}

//1 Route table for all PUBLIC subnets
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
  depends_on     = [aws_route_table.public_subnet_internet_route]
}

#-----------------------------NAT and EIP-----------------------------#

resource "aws_eip" "eip_for_nat" {
  for_each = local.nat_gateways_zones_and_subnets
  domain   = "vpc"
  tags = merge(local.default_tags, {
    Name = "Public-subnet-eip-${var.environment}${local.workspace}"
  })
}

resource "aws_nat_gateway" "nat_gw_for_private_subnet" {
  for_each      = local.nat_gateways_zones_and_subnets
  subnet_id     = local.nat_gateways_zones_and_subnets[each.key].subnet_id
  allocation_id = aws_eip.eip_for_nat[each.key].id
  tags = merge(local.default_tags, {
    Name = "NAT-gateway-${var.environment}${local.workspace}"
  })
  depends_on = [aws_eip.eip_for_nat, aws_eip.eip_for_nat]
}

#-----------------------------PRIVATE NETWORKS-----------------------------#

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnets_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]
  tags = merge(local.default_tags, {
    Name = "Private-subnet-${var.environment}${local.workspace}-${local.azs[count.index % length(local.azs)]}"
  })
}

//Route table for each PRIVATE subnets
resource "aws_route_table" "private_subnet_internet_route" {
  count  = length(aws_nat_gateway.nat_gw_for_private_subnet) > 0 ? length(aws_subnet.private_subnets) : 0
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = try(
      aws_nat_gateway.nat_gw_for_private_subnet[aws_subnet.private_subnets[count.index].availability_zone].id,
      values(aws_nat_gateway.nat_gw_for_private_subnet)[0].id
    )
  }
  tags = merge(local.default_tags, {
    Name = "Route-table-${var.environment}${local.workspace}"
  })
  depends_on = [aws_subnet.private_subnets, aws_nat_gateway.nat_gw_for_private_subnet]
}

resource "aws_route_table_association" "private_subnet_bind" {
  count          = length(aws_nat_gateway.nat_gw_for_private_subnet) > 0 ? length(aws_subnet.private_subnets) : 0
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_subnet_internet_route[count.index].id
  depends_on     = [aws_route_table.private_subnet_internet_route, aws_subnet.private_subnets]
}

#-----------------------------PRIVATE NETWORKS-----------------------------#

resource "aws_subnet" "db_subnets" {
  count             = length(var.db_subnets_cidrs)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.db_subnets_cidrs[count.index]
  availability_zone = local.azs[count.index % length(local.azs)]
  tags = merge(local.default_tags, {
    Name = "DB-subnet-${var.environment}${local.workspace}-${local.azs[count.index % length(local.azs)]}"
  })
}
