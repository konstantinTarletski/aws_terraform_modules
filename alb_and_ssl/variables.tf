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
    is_default   = bool
  }))
  default = { "8080" = { host = "www", priority = 10, health_check = "/", is_default = true } }
}

variable "alb_http_port" {
  type        = number
  default     = 80
  description = "ALB HTTP port, HTTPS automatically will be at 443"
}

variable "existing_domain_name" {
  type        = string
  default     = null
  description = "Domain name you owned in amazon, hosted zones NS and SOA suppose to be present"
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
  default     = { "80" = ["0.0.0.0/0"], "443" = ["0.0.0.0/0"] }
  description = "Default is: { '80' = ['0.0.0.0/0'] , '443' = ['0.0.0.0/0']}, Disable 443 if no domain !!!"
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
