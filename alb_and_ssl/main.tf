terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
}

locals {
  workspace         = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  long_project_name = "${var.project_name}-${var.environment}${local.workspace}"
  default_port      = one([for k, v in var.alb_port_mappings : k if v.is_default])
  default_tags = merge(var.default_tags, {
    Workspace = terraform.workspace
  })
}

resource "aws_security_group" "alb_sg" {
  name   = "ALB-SG-${local.long_project_name}"
  vpc_id = var.vpc_id
  tags = merge(local.default_tags, {
    Name = "ALB-SG-${var.environment}${local.workspace}"
  })
}

module "dev_ecs_service" {
  source                 = "git@github.com:konstantinTarletski/aws_terraform_modules.git//sg_rule_constructor"
  security_group_id      = aws_security_group.alb_sg.id
  ingress_ports_and_sg   = var.alb_sg_ingress_ports_and_sg
  ingress_ports_and_cidr = var.alb_sg_ingress_ports_and_cidr
  egress_ports_and_sg    = var.alb_sg_egress_ports_and_sg
  egress_ports_and_cidr  = var.alb_sg_egress_ports_and_cidr
  depends_on             = [aws_security_group.alb_sg]
}

resource "aws_lb" "alb" {
  name               = "ALB-${local.long_project_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets_ids

  tags = merge(local.default_tags, {
    Name = "ALB-${var.environment}${local.workspace}"
  })
}

resource "aws_lb_target_group" "port_tg" {
  for_each    = var.alb_port_mappings
  name        = "TG-${each.key}-${local.long_project_name}"
  port        = tonumber(each.key)
  protocol    = var.alb_protocol
  vpc_id      = var.vpc_id
  target_type = "ip" # Fot ECS Fargate use "ip", for EC2 - "instance"

  health_check {
    path                = each.value.health_check
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_port
  protocol          = var.alb_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_tg[local.default_port].arn
  }
}

resource "aws_lb_listener_rule" "rules" {
  for_each = { for k, v in var.alb_port_mappings : k => v if !v.is_default }

  listener_arn = aws_alb_listener.alb_listener.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_tg[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}
