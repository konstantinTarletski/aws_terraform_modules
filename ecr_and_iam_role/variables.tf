variable "ecr_repository_name" {
  type    = string
  default = "some_name"
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

variable "git-repository-owner" {
  type    = string
  default = "owner"
}

variable "git-repository-name" {
  type    = string
  default = "some-repository"
}

variable "git-repository-token-link" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}
