output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "ports_with_target_groups" {
  value       = { for k, v in aws_lb_target_group.port_tg : k => v.arn }
  description = "Example: ['80080' = 'arn:tg-123']"
}

output "default_target_group_arn" {
  value = aws_lb_target_group.port_tg[local.default_port].arn
}

output "ports_and_tg_arns_map" {
  value = { for k, v in aws_lb_target_group.port_tg : k => { tg_arn = v.arn } }
  description = "Example: ['80080' = {tg_arn = 'arn:tg-123'}]"
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}
