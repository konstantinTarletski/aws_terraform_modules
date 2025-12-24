data "tls_certificate" "git_cert" {
  url = var.git_repository_token_link
}
