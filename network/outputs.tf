output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.main_vpc.cidr_block
}

output "public_subnets_ids_and_cidrs" {
  value = local.public_subnets_by_az
}

output "private_subnets_ids_and_cidrs" {
  value = local.private_subnets_by_az
}

output "db_subnets_ids_and_cidrs" {
  value = local.db_subnets_by_az
}

output "nat_subnets_and_zones" {
  value = local.nat_gateways_zones_and_subnets
}