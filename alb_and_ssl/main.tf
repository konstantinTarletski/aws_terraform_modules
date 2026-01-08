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
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
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
  protocol    = "HTTP"
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

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.existing_domain_name != null ? 443 : var.alb_http_port
  protocol          = var.existing_domain_name != null ? "HTTPS" : "HTTP"
  ssl_policy        = var.existing_domain_name != null ? local.ssl_policy : null
  certificate_arn   = var.existing_domain_name != null ? aws_acm_certificate_validation.cert[0].certificate_arn : null
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_tg[local.default_port].arn
  }
}

resource "aws_lb_listener_rule" "rules" {
  for_each     = { for k, v in var.alb_port_mappings : k => v if !v.is_default }
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.port_tg[each.key].arn
  }

  condition {
    host_header {
      //compact - removes "null" values
      values = compact([
        var.existing_domain_name != null ? "${each.value.host}.${var.existing_domain_name}" : null,
        "${each.value.host}.${aws_lb.alb.dns_name}"
      ])
    }
  }
}

resource "aws_lb_listener" "alb_listener_redirect" {
  count             = var.existing_domain_name != null ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#-----------------------------Route 53-----------------------------#

resource "aws_acm_certificate" "cert" {
  count             = var.existing_domain_name != null ? 1 : 0
  domain_name       = var.existing_domain_name
  subject_alternative_names = ["*.${var.existing_domain_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "domain_hosted_zone" {
  count        = var.existing_domain_name != null ? 1 : 0
  name         = "${var.existing_domain_name}." // adding "."
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.existing_domain_name != null ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.existing_domain_name != null ? data.aws_route53_zone.domain_hosted_zone[0].zone_id : null
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = var.existing_domain_name != null ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "hosted_zone_record_a_wildcard" {
  count   = var.existing_domain_name != null ? 1 : 0
  zone_id = data.aws_route53_zone.domain_hosted_zone[0].zone_id
  name    = "*.${var.existing_domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

  resource "aws_route53_record" "hosted_zone_record_a_domain" {
    count   = var.existing_domain_name != null ? 1 : 0
    zone_id = data.aws_route53_zone.domain_hosted_zone[0].zone_id
    name    = var.existing_domain_name
    type    = "A"

    alias {
      name                   = aws_lb.alb.dns_name
      zone_id                = aws_lb.alb.zone_id
      evaluate_target_health = true
    }
}
