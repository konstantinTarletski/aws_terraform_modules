output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_id" {
  value = aws_lb.alb.id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "ports_with_target_groups" {
  value       = { for k, v in aws_lb_target_group.port_tg : k => v.arn }
  description = "{'port1' = 'tg_arn_2'},{'port1' = 'tg_arn_2'}"
}

output "ports_and_tg_arns_map" {
  value       = { for k, v in aws_lb_target_group.port_tg : k => { tg_arn = v.arn } }
  description = "['80080' = {tg_arn = 'arn:tg-123'}]"
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "alb_url" {
  description = "Base URL of your Load Balancer"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "service_urls" {
  description = "API links to the application"
  value = var.existing_domain_name != null ? {
    for k, v in var.alb_port_mappings : v.host => "https://${v.host}.${var.existing_domain_name}"
  } : {
    for k, v in var.alb_port_mappings : v.host => "http://${aws_lb.alb.dns_name}:${k}"
  }
}
