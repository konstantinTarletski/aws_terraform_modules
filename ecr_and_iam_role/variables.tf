variable "ecr_repository_name" {
  type    = string
}

variable "default_tags" {
  type        = map(string)
  description = "List of default tags"
  default = {
    Manufactor = "terraform",
    Design     = "tarlekon"
  }
}

variable "docker_images_hold_count" {
  type    = number
  default = 5
}

variable "git_repository_owner" {
  type    = string
  default = "owner"
}

variable "git_repository_name" {
  type    = string
}

variable "ecr_force_delete" {
  type = bool
  default = false
}

variable "git_repository_token_link" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}
