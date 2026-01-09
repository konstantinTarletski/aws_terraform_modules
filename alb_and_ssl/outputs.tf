output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_id" {
  value = aws_lb.alb.id
}

output "alb_arn" {
  value = aws_lb.alb.arn
}

output "aws_lb_listener_id" {
  value = one(concat(
    aws_lb_listener.alb_http_mode_listener[*].id,
    aws_lb_listener.alb_https_mode_listener[*].id
  ))
}
output "ports_with_target_groups" {
  value       = { for k, v in aws_lb_target_group.port_tg : k => v.arn }
  description = "{'port1' = 'tg_arn_2'},{'port1' = 'tg_arn_2'}"
}

output "default_target_group_arn" {
  value = aws_lb_target_group.port_tg[local.default_port].arn
}

output "ports_and_tg_arns_map" {
  value       = { for k, v in aws_lb_target_group.port_tg : k => { tg_arn = v.arn } }
  description = "['80080' = {tg_arn = 'arn:tg-123'}]"
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}
