variable "security_group_id" {
  type = string
  description = "Security group id to populate with rules"
}

variable "ingress_ports_and_sg" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '8080' = ['sg-123', 'sg-456'] }"
}

variable "ingress_ports_and_cidr" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '8080' = ['10.0.0.0/16', '1.2.3.4/32'] }"
}

variable "egress_ports_and_sg" {
  type        = map(list(string))
  default     = {}
  description = "Example: { '443' = ['sg-123', 'sg-456'] }"
}

variable "egress_ports_and_cidr" {
  type        = map(list(string))
  default     = { "443" = ["0.0.0.0/0"] }
  description = "Default is : { '443' = ['0.0.0.0/0'] }; For able Docker images download"
}