# 🚀 ECS Fargate Service & Security Orchestrator

> **Architectural Note:** This module is an original, custom-built solution developed during an in-depth Terraform study. I deliberately avoided using public third-party modules (like `terraform-aws-modules`) to implement proprietary resource management logic and ensure granular control over every AWS infrastructure component.

## 🏛 Architectural Design & Security

This module serves as the primary engine for deploying containerized applications on **AWS ECS Fargate**. It orchestrates the entire lifecycle of a microservice, from Task Definition and IAM roles to complex networking rules and Load Balancer integration.

## 🏗 Key Features

### 1. Dynamic Security Group Constructor
The core strength of this module is its highly flexible **Security Group (SG) logic**. It allows for precise ingress/egress control without the risks of circular dependencies:
*   **Targeted Ingress:** Automatically allows traffic only from specified sources (e.g., restricted access from the ALB Security Group on application ports).
*   **Isolation:** Services are strictly provisioned in **Private Subnets** with no public IP assignment, enforcing a secure traffic flow through the Load Balancer.

### 2. Modern CI/CD Integration (OIDC)
The module integrates with **GitHub Actions** via **OpenID Connect (OIDC)**:
*   **Keyless Authentication:** Securely links GitHub repositories to ECS IAM roles, allowing deployment pipelines to interact with AWS without storing permanent Access Keys.
*   **Least Privilege:** Separate IAM roles for **Task Execution** (AWS internal operations) and **Task Role** (Application permissions) are provisioned following best security practices.

### 3. Advanced ALB Integration
*   **Dynamic Port Mapping:** Automatically maps application ports to their respective **Target Group ARNs**, retrieved dynamically from the ALB module.
*   **Observability:** Integrated CloudWatch logging with custom log group management, ensuring immediate visibility into container logs (stdout/stderr).

## 🛠 Engineering Excellence
*   **Strict Pull Policy:** Supports `docker_image_strict_pull_policy` to ensure that only verified and expected image versions are deployed.
*   **Environment Orchestration:** Seamlessly passes complex environment variable maps from remote states to the Fargate task definition.
*   **Serverless Efficiency:** Fully managed Fargate capacity provider, eliminating EC2 management overhead while ensuring high availability.

## 📦 Integration Example

This example demonstrates a production-grade deployment using **Terraform Remote State** to stitch together Network, ECR, and ALB components.

```hcl
module "dev_ecs_service" {
  source = "git@github.com:konstantinTarletski/aws_terraform_modules.git//ecs_service_and_iam_roles?ref=v2.1.0"

  # Networking & ECR Integration
  vpc_id              = data.terraform_remote_state.network.outputs.vpc_id
  subnets_ids         = data.terraform_remote_state.network.outputs.private_subnets_ids
  ecr_repository_url  = data.terraform_remote_state.ecr.outputs.ecr_url
  ecr_repository_name = data.terraform_remote_state.shared.outputs.ecr_name

  # GitHub Actions Security (OIDC)
  git_repository_owner     = data.terraform_remote_state.globalvars.outputs.git_owner
  git_repository_name      = data.terraform_remote_state.shared.outputs.git_repo_name
  git_open_id_provider_arn = data.terraform_remote_state.ecr.outputs.git_open_id_provider_arn

  # Dynamic ALB Mapping & Traffic Security
  # Maps internal container ports to ALB Target Groups
  ecs_sg_application_ports_and_tg_arn = data.terraform_remote_state.alb.outputs.ports_and_tg_arns_map
  
  # Strictly allow ingress traffic only from the ALB Security Group
  ecs_sg_ingress_ports_and_sg = { 
    "8815" = [data.terraform_remote_state.alb.outputs.alb_sg_id] 
  }

  # Observability & Config
  aws_cloudwatch_log_group        = "/ecs/game-sys-test-task"
  region                          = data.aws_region.current.id
  docker_image_strict_pull_policy = true
  environment_variables           = data.terraform_remote_state.shared.outputs.env_vars
  
  default_tags = data.terraform_remote_state.globalvars.outputs.default_tags
}
