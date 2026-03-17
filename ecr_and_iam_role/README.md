# 🏗️ ECS Service Identity & ECR Registry Module (OIDC Integrated)

> **Architectural Note:** This module is an original, custom-built solution developed during an in-depth Terraform study. I deliberately avoided using public third-party modules (like `terraform-aws-modules`) to implement proprietary resource management logic and ensure granular control over every AWS infrastructure component.

## 🏛 Architectural Design & Security

This module provides a secure runtime environment and image lifecycle management for containerized applications in **AWS ECS Fargate**. It follows the **Security-by-Design** principles by implementing a strict Identity and Access Management (IAM) model.

## 🏗 Key Features

### 1. Advanced IAM Trust Model (OIDC Integration)
Unlike legacy approaches using static IAM user credentials, this module implements **OpenID Connect (OIDC)** for GitHub Actions.
*   **Key-less Security:** It allows GitHub Actions runners to assume IAM roles via temporary tokens, eliminating the need to store long-lived AWS Access Keys in GitHub Secrets.
*   **Granular Trust:** Trust policies are strictly scoped to specific GitHub repositories and owners, ensuring that only authorized CI/CD pipelines can push images to your ECR.

### 2. Dual-Role IAM Isolation (Least Privilege)
The module enforces a strict separation of concerns by provisioning two distinct roles:
*   **ECS Task Execution Role**: Scoped exclusively to the ECS Agent. It allows pulling images from ECR and pushing logs to CloudWatch.
*   **ECS Task Role**: Represents the application's "Identity". It is initially empty and intended to be granted specific permissions only for required resources (e.g., S3, RDS, SQS), isolating the infrastructure from the application code.

### 3. Production-Ready ECR Management
*   **Image Immutability**: Configured to prevent overwriting existing image tags, ensuring stable and predictable rollbacks.
*   **Lifecycle Management**: Includes automated cleanup policies to remove untagged or obsolete images, preventing uncontrolled growth of S3 storage costs.
*   **Force Delete Logic**: Includes a safety toggle for automated environments where rapid teardowns are required.

## 📦 Integration Example

This example demonstrates how to link your **ECR registry** and **IAM roles** directly to your **GitHub repository** for a secure, automated CI/CD pipeline.

```hcl
module "dev_ecr_repo" {
  source = "git@github.com:konstantinTarletski/aws_terraform_modules.git//ecr_and_iam_role?ref=v1.2.0"

  # Integration with GitHub Actions (OIDC)
  git_repository_owner      = data.terraform_remote_state.globalvars.outputs.github_owner
  git_repository_name       = data.terraform_remote_state.shared.outputs.repo_name
  git_repository_token_link = "https://token.actions.githubusercontent.com"

  # Container Registry Configuration
  ecr_repository_name       = data.terraform_remote_state.shared.outputs.ecr_name
  ecr_force_delete          = true # Critical for clean DEV environment teardowns

  # Metadata
  default_tags = data.terraform_remote_state.globalvars.outputs.default_tags
}
