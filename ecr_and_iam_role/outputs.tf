output "aws_iam_pusher_role_name" {
  value = aws_iam_role.ecr_pusher.name
}

output "aws_iam_pusher_role_id" {
  value = aws_iam_role.ecr_pusher.id
}

output "aws_ecr_repository_name" {
  value = aws_ecr_repository.ecr_repository.name
}

output "aws_ecr_repository_id" {
  value = aws_ecr_repository.ecr_repository.id
}