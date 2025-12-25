locals {
  ecs_cluster_id = var.existing_cluster_id != null ? data.aws_ecs_cluster.existing[0].id : aws_ecs_cluster.new_cluster[0].id
  workspace      = terraform.workspace == "default" ? "" : "-${terraform.workspace}"
  default_tags = merge(var.default_tags, {
    Workspace = terraform.workspace
  })
}

//Creating only "existing" not defined
resource "aws_ecs_cluster" "new_cluster" {
  count = var.existing_cluster_id == null ? 1 : 0
  name  = "Cluster_${var.environment}${local.workspace}"
  tags = merge(local.default_tags, {
    Name = "ECS_Cluster-${var.environment}${local.workspace}"
  })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = var.aws_cloudwatch_log_group
  retention_in_days = var.aws_cloudwatch_log_retention_in_days
}

resource "aws_security_group" "ecs_public_sg" {
  name        = "SG_for_appliation_${var.application_name}${var.environment}${local.workspace}"
  description = "Opens ports dynamically"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.application_ports
    content {
      cidr_blocks = var.application_sg_ingress_cider_blocks
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
    }
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = merge(local.default_tags, {
    Name = "ECS_SG-${var.application_name}${var.environment}${local.workspace}"
  })
}

resource "aws_iam_role" "ecs_exec_role" {
  name = "${var.application_name}_execution-role_${var.environment}${local.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = merge(local.default_tags, {
    Name = "ECS_exec_role-${var.application_name}${var.environment}${local.workspace}"
  })
}

resource "aws_iam_policy" "strict_ecr_pull" {
  name = "${var.application_name}_strict_ecr_pull_policy_${var.environment}${local.workspace}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = var.docker_image_strict_pull_policy ? "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}" : "*"
      },
      {
        Action   = "ecr:GetAuthorizationToken"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.ecs_logs.arn}:*"
      }
    ]
  })
  tags = merge(local.default_tags, {
    Name = "ECS_exec_policy-${var.application_name}${var.environment}${local.workspace}"
  })
}

resource "aws_iam_role_policy_attachment" "attach_strict_pull" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = aws_iam_policy.strict_ecr_pull.arn
}

resource "aws_iam_policy" "github_deploy_policy" {
  name = "GithubDeployOnly"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ecs:RegisterTaskDefinition"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "iam:PassRole"
        Effect   = "Allow"
        Resource = aws_iam_role.ecs_exec_role.arn
      }
    ]
  })
  tags = merge(local.default_tags, {
    Name = "ECS_deploy_policy-${var.application_name}${var.environment}${local.workspace}"
  })
}

resource "aws_iam_role_policy_attachment" "attach_github" {
  role       = "ecr-pusher_repo_${var.application_name}"
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.application_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.application_name}_container_definitions"
      image     = var.ecr_repository_url != "" ? "${var.ecr_repository_url}:${var.docker_image_tag}" : var.docker_default_image_name
      essential = true
      portMappings = [
        for p in var.application_ports : {
          containerPort = p
          hostPort      = p
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  tags = merge(local.default_tags, {
    Name = "ECS_task_definition-${var.application_name}${var.environment}${local.workspace}"
  })
}

resource "aws_ecs_service" "main" {
  name            =  "${var.application_name}${var.environment}${local.workspace}_service"
  cluster         = local.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.instance_replica_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.subnets_ids
    //In aws_subnet there is "  map_public_ip_on_launch = true"
    //but in not works for "Fargate"
    // There are "special" for "Fargate", see next:
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_public_sg.id]
  }
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  tags = merge(local.default_tags, {
    Name = "ECS_service-${var.application_name}${var.environment}${local.workspace}"
  })
}
