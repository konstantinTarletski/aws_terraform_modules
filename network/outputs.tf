output "vpc_id_and_cidr" {
  value = {(aws_vpc.main_vpc.id) = aws_vpc.main_vpc.cidr_block}
}

output "public_subnets_ids_and_cidrs" {
  value = {
    for s in aws_subnet.public_subnets :
    s.id => {
      cidr_block = s.cidr_block
      az         = s.availability_zone
    }
  }
}

output "private_subnets_ids_and_cidrs" {
  value = {

  }
}

output "db_subnets_ids_and_cidrs" {
  value = {

  }
}

