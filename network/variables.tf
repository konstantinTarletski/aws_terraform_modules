variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

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

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "Have Internet connection. !!Number of subnets can be bigger then AZ!!"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "Have Internet connection through NAT. !!Number of subnets can be bigger then AZ!!"
  default = [
    //"10.0.101.0/24",
    //"10.0.102.0/24",
    //"10.0.103.0/24"
  ]
}

variable "db_subnets_cidrs" {
  type        = list(string)
  description = "Do not have Internet connection. !!Number of subnets can be bigger then AZ!!"
  default = [
    "10.0.201.0/24",
    "10.0.202.0/24",
    "10.0.203.0/24"
  ]
}
