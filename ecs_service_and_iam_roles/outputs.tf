output "iam_ecs_exec_role_arn" {
  value = aws_iam_role.ecs_exec_role.arn
}

output "ecs_service_name" {
  value = aws_ecs_service.main.name
}

output "ecs_service_arn" {
  value = aws_ecs_service.main.arn
}
