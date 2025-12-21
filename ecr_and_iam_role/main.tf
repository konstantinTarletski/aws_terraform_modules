terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.17.0"
    }
  }
}

locals {
  workspace = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  default_tags = merge(var.default_tags, {
    Workspace = terraform.workspace
  })
}

resource "aws_ecr_repository" "ecr_repository" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete = var.ecr_force_delete
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = merge(local.default_tags, {
    Name = "ECR${local.workspace}"
  })
}

resource "aws_ecr_lifecycle_policy" "keep_last_x" {
  repository = aws_ecr_repository.ecr_repository.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.docker_images_hold_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_iam_role" "ecr_pusher" {
  name = "ecr-pusher_repo_${var.ecr_repository_name}${local.workspace}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          //"token.actions.githubusercontent.com:sub" = "repo:ORG/REPO:*"
          "token.actions.githubusercontent.com:sub" = "repo:${var.git_repository_owner}/${var.git_repository_name}:*"
        }
      }
    }]
  })
  tags = merge(local.default_tags, {
    Name = "ECR-pusher_repo=${var.git_repository_name}${local.workspace}"
  })
}

resource "aws_iam_role_policy" "ecr_push_policy" {
  role = aws_iam_role.ecr_pusher.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = aws_ecr_repository.ecr_repository.arn
      }
    ]
  })
}

data "tls_certificate" "git_cert" {
  url = var.git_repository_token_link
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = var.git_repository_token_link
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.git_cert.certificates[0].sha1_fingerprint]
  tags = merge(local.default_tags, {
    Name = "OID-GIT-provider${local.workspace}"
  })
}
