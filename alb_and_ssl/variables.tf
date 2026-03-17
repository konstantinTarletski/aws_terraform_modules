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
    Module     = "alb_and_ssl"
  }
}

variable "project_name" {
  type = string
}

variable "alb_port_mappings" {
  type = map(object({
    host         = string
    priority     = number
    health_check = string
  }))
  default = { "8080" = { host = "www", priority = 10, health_check = "/"} }
  description = "{ '8080' = { host = 'www', priority = 10, health_check = '/'} }"
}

variable "existing_domain_name" {
  type        = string
  default     = null
  description = "Domain name you owned in amazon, hosted zones NS and SOA suppose to be present"
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  description = "SSL policy for aws_lb_listener"
}

variable "vpc_id" {
  type = string
  description = "Virtual private cloud ID"
}

variable "subnets_ids" {
  type = list(string)
  description = "Virtual private cloud subnets"
}

variable "alb_sg_cidr" {
  type = list(string)
  description = "Opened CIDR blocs for ALB"
  default = ["0.0.0.0/0"]
}
