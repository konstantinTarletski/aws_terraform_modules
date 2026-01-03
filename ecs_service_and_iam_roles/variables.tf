variable "environment" {
  type    = string
  default = "dev"
}

variable "default_tags" {
  type        = map(string)
  description = "List of default tags"
  default = {
    Manufactor = "terraform",
    Design     = "tarlekon"
  }
}

variable "existing_cluster_id" {
  description = "ID of existing cluster. If not defined, new one will be created"
  type        = string
  default     = null
}

variable "vpc_id" {
  type = string
}

variable "region" {
  type = string
}

variable "subnets_ids" {
  type = list(string)
}

variable "ecr_repository_name" {
  type = string
}

variable "git_repository_owner" {
  type = string
}

variable "git_repository_name" {
  type        = string
  description = "Will be used like \"application name\" in tags and resource names"
}

variable "instance_replica_count" {
  type    = number
  default = 1
}

variable "aws_cloudwatch_log_group" {
  type = string
}

variable "aws_cloudwatch_log_retention_in_days" {
  type    = string
  default = 7
}

variable "ecs_sg_application_ports_and_tg_arn" {
  type        = map(object({ tg_arn = string }))
  default     = { "8080" = { tg_arn = null } }
  description = "Application ports allowed for ingress for ECS 8080 default for tomcat"
}

variable "ecs_sg_ingress_security_groups" {
  type        = list(string)
  description = "Application groups allowed for ingress for ECS"
}

variable "application_sg_ingress_cider_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "task_definition_cpu" {
  type    = string
  default = "256"
}

variable "task_definition_memory" {
  type    = string
  default = "512"
}

variable "environment_variables" {
  description = "Environment variables for task definition"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "ecr_repository_url" {
  type = string
}

variable "docker_default_image_name" {
  type    = string
  default = "tomcat"
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

variable "docker_image_strict_pull_policy" {
  type    = bool
  default = true
}

variable "git_open_id_provider_arn" {
  type = string
}
