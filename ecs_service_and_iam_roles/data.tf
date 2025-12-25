data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "existing" {
  count        = var.existing_cluster_id != null ? 1 : 0
  cluster_name = var.existing_cluster_id
}