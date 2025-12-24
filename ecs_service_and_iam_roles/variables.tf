variable "cluster_name" {
  type    = string
  default = "dev-cluster"
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

variable "application_name" {
  type = string
}

variable "aws_cloudwatch_log_group" {
  type = string
}

variable "aws_cloudwatch_log_retention_in_days" {
  type    = string
  default = 7
}

variable "application_ports" {
  type    = list(number)
  default = [8080]
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

variable "docker_image_name" {
  type    = string
  default = "tomcat:latest"
}

variable "docker_image_strict_pull_policy" {
  type    = bool
  default = true
}
