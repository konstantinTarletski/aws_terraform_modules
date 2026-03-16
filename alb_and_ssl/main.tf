terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30"
    }
  }
}

locals {
  workspace         = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  long_project_name = "${var.project_name}-${var.environment}${local.workspace}"
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
  source                 = "git@github.com:konstantinTarletski/aws_terraform_modules.git//sg_rule_constructor?ref=feature/alb-refactoring-improved"
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

#-----------------------------VERSION 2-----------------------------#

#----HTTP MODE (splitting by PORT)----#
resource "aws_lb_listener" "alb_http_listener" {
  for_each          = var.alb_port_mappings
  load_balancer_arn = aws_lb.alb.arn
  port              = each.key
  protocol          = "HTTP"

  default_action {
    type = var.existing_domain_name == null ? "forward" : "redirect"

    dynamic "forward" {
      for_each = var.existing_domain_name == null ? [1] : []
      content {
        target_group_arn = aws_lb_target_group.port_tg[each.key].arn
      }
    }

    dynamic "redirect" {
      for_each = var.existing_domain_name != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

#----HTTPS MODE ----#
resource "aws_lb_listener" "alb_https_listener" {
  count             = var.existing_domain_name != null ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = one(aws_acm_certificate_validation.cert[*].certificate_arn)

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Service Not Found. Please use subdomains like www. или api."
      status_code  = "404"
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

#----HTTPS ROUTING RULES----#
resource "aws_lb_listener_rule" "host_based_routing" {
  for_each = var.existing_domain_name != null ? var.alb_port_mappings : {}

  listener_arn = one(aws_lb_listener.alb_https_listener[*].arn)
  priority     = each.value.priority

  action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.port_tg[each.key].arn
      }
    }
  }

  condition {
    dynamic "host_header" {
      for_each = var.existing_domain_name != null ? [1] : []
      content {
        values = ["${each.value.host}.${var.existing_domain_name}"]
      }
    }
  }
}

#-----------------------------Route 53-----------------------------#

resource "aws_acm_certificate" "cert" {
  count                     = var.existing_domain_name != null ? 1 : 0
  domain_name               = var.existing_domain_name
  subject_alternative_names = ["*.${var.existing_domain_name}"]
  validation_method         = "DNS"

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
    for dvo in flatten(aws_acm_certificate.cert[*].domain_validation_options) : dvo.domain_name => {
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
  certificate_arn         = one(aws_acm_certificate.cert[*].arn)
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "hosted_zone_record_a_wildcard" {
  count   = var.existing_domain_name != null ? 1 : 0
  zone_id = one(data.aws_route53_zone.domain_hosted_zone[*].zone_id)
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
