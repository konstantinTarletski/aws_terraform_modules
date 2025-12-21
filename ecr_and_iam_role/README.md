# ecr_and_iam_role

Terraform module for creating an AWS ECR repository and an IAM Role
for pushing Docker images from GitHub Actions using OIDC.

---

## What this module creates

- AWS ECR repository
- ECR lifecycle policy (keep last N images)
- GitHub OIDC provider (via `tls_certificate`)
- IAM Role with permissions to push images to ECR

---

## Usage

```hcl
module "dev-ecr-repo" {
  source      = "git@github.com:konstantinTarletski/aws_terraform_modules.git//ecr_and_iam_role"
  ecr_repository_name = "game-sys-test-task"
  git-repository-name = "game-sys-test-task"
  git-repository-owner = "konstantinTarletski"
  git-repository-token-link = "https://token.actions.githubusercontent.com"
  default_tags = {
    Manufactor = "terraform",
    Design     = "tarlekon",
    Source     = "module"
  }
}
```

## Output
| Name                       | Description                |
| -------------------------- | -------------------------- |
| `aws_ecr_repository_name`  | ECR repository name        |
| `aws_ecr_repository_id`    | ECR repository ID          |
| `aws_iam_pusher_role_name` | IAM Role name for ECR push |
| `aws_iam_pusher_role_id`   | IAM Role ID                |

## Created AWS resources

| Resource | Type | Purpose |
|--------|------|--------|
| ECR repository | `aws_ecr_repository` | Stores Docker images |
| ECR lifecycle policy | `aws_ecr_lifecycle_policy` | Keeps last N images |
| IAM role | `aws_iam_role` | Role assumed by GitHub Actions |
| IAM role policy | `aws_iam_role_policy` | Allows pushing images to ECR |
| OIDC provider | `aws_iam_openid_connect_provider` | Trusts GitHub Actions |
| TLS certificate data | `data.tls_certificate` | Resolves OIDC thumbprint dynamically |


