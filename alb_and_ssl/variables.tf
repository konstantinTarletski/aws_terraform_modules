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
  type        = string
}

variable "alb_port_mappings" {
  type = map(object({
    path_pattern = string
    priority     = number
    health_check = string
    is_default   = bool
  }))
  default = { "8080" = { path_pattern = "/*", priority = 10, health_check = "/", is_default = true } }
}

variable "alb_port" {
  type    = number
  default = 80
  description = "ALB port"
}

variable "alb_protocol" {
  type = string
  default       = "HTTP"
  description = "ALB protocol"
}

variable "vpc_id" {
  type = string
}

variable "subnets_ids" {
  type = list(string)
}

variable "alb_sg_ingress_ports_and_sg" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '8080' = ['sg-123', 'sg-456'] }"
}

variable "alb_sg_ingress_ports_and_cidr" {
  type        = map(list(string))
  default     = { "80" = ["0.0.0.0/0"] }
  description = "Default is: { '80' = ['0.0.0.0/0'] }"
}

variable "alb_sg_egress_ports_and_sg" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '443' = ['sg-123', 'sg-456'] }"
}

variable "alb_sg_egress_ports_and_cidr" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '443' = ['0.0.0.0/0'] }"
}
