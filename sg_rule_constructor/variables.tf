variable "security_group_id" {
  type = string
  description = "Security group id to populate with rules"
}

#-----------------------------AUTO RULE "KEY" GENERATION-----------------------------#

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
  default     = {}
  description = "Example : { '443' = ['0.0.0.0/0'] }"
}

#-----------------------------NAMED RULE "KEY"-----------------------------#

variable "ingress_ports_and_sg_named" {
  type = map(object({
    port  = string
    sg_id = string
  }))
  default     = {}
  description = "Example: { 'rule_name_1' = {port = '8080', cidr = 'sg-123'} , 'rule_name_2' = {port = '8081', cidr = 'sg-456'} }"
}

variable "egress_ports_and_sg_named" {
  type = map(object({
    port  = string
    sg_id = string
  }))
  default = {}
  description = "Example: { 'rule_name_1' = {port = '8080', sg_id = 'sg-123'} , 'rule_name_2' = {port = '8081', sg_id = 'sg-456'} }"
}

