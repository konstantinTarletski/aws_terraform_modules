# Terraform AWS Infrastructure Modules

This repository contains reusable Terraform modules for building AWS infrastructure.

Each module is **self-contained**, production-oriented, and documented individually.

## Modules

| Module | Description |
|------|-------------|
| `network` | VPC with public, private (NAT), and isolated DB subnets |
| `ecr_and_iam_role` | ECR repository with lifecycle policy and GitHub Actions IAM role |

👉 **See each module directory for detailed documentation and usage examples.**

## Design principles

- Modular and composable
- Minimal AWS resources (cost-aware)
- No hardcoded Availability Zones
- Workspace-aware naming
- Suitable for CI/CD and multi-environment setups
