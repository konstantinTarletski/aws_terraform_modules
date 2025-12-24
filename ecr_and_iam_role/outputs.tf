output "aws_iam_pusher_role_name" {
  value = aws_iam_role.ecr_pusher.name
}

output "aws_iam_pusher_role_id" {
  value = aws_iam_role.ecr_pusher.id
}

output "aws_iam_pusher_role_arn" {
  value = aws_iam_role.ecr_pusher.arn
}

output "aws_ecr_repository_name" {
  value = aws_ecr_repository.ecr_repository.name
}

output "aws_ecr_repository_id" {
  value = aws_ecr_repository.ecr_repository.id
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.ecr_repository.repository_url
}