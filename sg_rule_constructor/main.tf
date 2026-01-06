terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
}

#-----------------------------AUTO RULE "KEY" GENERATION-----------------------------#

resource "aws_vpc_security_group_ingress_rule" "ingress_cidr" {
  for_each = {
    for pair in flatten([
      for port, cidr_list in var.ingress_ports_and_cidr : [
        for cidr in cidr_list : { port = port, cidr = cidr }
      ]
    ]) : "${pair.port}_${pair.cidr}" => pair
  }

  security_group_id = var.security_group_id
  from_port         = tonumber(each.value.port)
  to_port           = tonumber(each.value.port)
  ip_protocol       = var.ip_protocol
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_ingress_rule" "ingress_sg" {
  for_each = {
    for pair in flatten([
      for port, sg_list in var.ingress_ports_and_sg : [
        for sg_id in sg_list : { port = port, sg_id = sg_id }
      ]
    ]) : "${pair.port}_${pair.sg_id}" => pair
  }

  security_group_id            = var.security_group_id
  from_port                    = tonumber(each.value.port)
  to_port                      = tonumber(each.value.port)
  ip_protocol                  = var.ip_protocol
  referenced_security_group_id = each.value.sg_id
}

resource "aws_vpc_security_group_egress_rule" "egress_cidr" {
  for_each = {
    for pair in flatten([
      for port, cidr_list in var.egress_ports_and_cidr : [
        for cidr in cidr_list : { port = port, cidr = cidr }
      ]
    ]) : "${pair.port}_${pair.cidr}" => pair
  }

  security_group_id = var.security_group_id
  from_port         = tonumber(each.value.port)
  to_port           = tonumber(each.value.port)
  ip_protocol       = var.ip_protocol
  cidr_ipv4         = each.value.cidr
}

resource "aws_vpc_security_group_egress_rule" "egress_sg" {
  for_each = {
    for pair in flatten([
      for port, sg_list in var.egress_ports_and_sg : [
        for sg_id in sg_list : { port = port, sg_id = sg_id }
      ]
    ]) : "${pair.port}_${pair.sg_id}" => pair
  }

  security_group_id            = var.security_group_id
  from_port                    = tonumber(each.value.port)
  to_port                      = tonumber(each.value.port)
  ip_protocol                  = "tcp"
  referenced_security_group_id = each.value.sg_id
}

#-----------------------------NAMED RULE "KEY"-----------------------------#

resource "aws_vpc_security_group_ingress_rule" "egress_sg_named" {
  for_each = var.ingress_ports_and_sg_named

  security_group_id            = var.security_group_id
  from_port                    = tonumber(each.value.port)
  to_port                      = tonumber(each.value.port)
  ip_protocol                  = var.ip_protocol
  referenced_security_group_id = each.value.sg_id
}

resource "aws_vpc_security_group_egress_rule" "egress_sg_named" {
  for_each = var.egress_ports_and_sg_named

  security_group_id            = var.security_group_id
  from_port                    = tonumber(each.value.port)
  to_port                      = tonumber(each.value.port)
  ip_protocol                  = var.ip_protocol
  referenced_security_group_id = each.value.sg_id
}
