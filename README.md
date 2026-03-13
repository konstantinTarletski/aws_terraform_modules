# 🏗️ Custom-Built AWS Infrastructure Modules (Terraform)

> **Architectural Note:** This repository is a product of an in-depth Terraform study. I deliberately avoided using public third-party modules (e.g., `terraform-aws-modules`) to implement proprietary resource management logic from scratch. My goal was to achieve granular control over every AWS component and solve complex infrastructure challenges such as **URL Rewrite limitations**, **Circular Dependencies**, and **Multi-AZ Cost Optimization**.

## 🌟 Project Philosophy
I’ve invested significant effort into making these modules truly **universal and production-ready**. Each module acts as an adaptive system, allowing for seamless transitions between environments (Dev/Prod) without modifying the internal logic of the applications or the infrastructure code itself.

---

## 📂 Modules Ecosystem (Click to Explore)

### 🛡️ [**Smart ALB & SSL Automation**](./alb_and_ssl)
**The Problem Solver.** This is the most complex module in the collection.
*   **The Innovation:** Implements "Smart Port Mapping" to bypass the lack of native URL Rewrite in AWS ALB.
*   **Impact:** Ensures **Swagger UI** and API paths remain intact (`/`) in both Port-based (No-Domain) and Host-based (SSL/Domain) modes.
*   **Tech Highlights:** Zero-downtime listener switching using `dynamic` blocks and `one()`/`flatten()` logic.

### 🌐 [**High-Availability Multi-Tier VPC**](./network)
**The Foundation.** A flexible network engine that scales beyond AWS regional limits.
*   **The Innovation:** Automated 3-tier segmentation (Public/Private/DB) with a **Smart NAT Controller**.
*   **Impact:** Optimizes costs by using "NAT-per-AZ" logic and automated cross-zone routing if a local NAT gateway is missing in a specific zone.
*   **Tech Highlights:** Dynamic subnet distribution using `cidrsubnet` and modulo-based availability zone mapping.

### 🚀 [**ECS Fargate Service & Security Orchestrator**](./ecs_service_and_iam_roles)
**The Engine.** Manages the full lifecycle of containerized microservices.
*   **The Innovation:** Integrated **GitHub Actions OIDC** support for keyless authentication.
*   **Impact:** Strictly enforces "Least Privilege" by separating Task and Execution IAM roles.
*   **Tech Highlights:** Dynamic binding of container ports to ALB Target Groups and centralized CloudWatch observability.

### 🔐 [**Security Group Rule Constructor**](./sg_rule_constructor)
**The Logic Decoupler.** A utility module to solve the "Chicken and Egg" dependency problem.
*   **The Innovation:** Eliminates **Circular Dependencies** by decoupling Security Group creation from rule injection.
*   **Impact:** Supports "Named Rules," enabling multiple distinct rules for the same port (e.g., separating ALB ingress from VPN access).
*   **Tech Highlights:** Purely declarative firewall management using `for_each` mapping.

### 📦 [**ECS Service Identity & ECR Registry**](./ecr_and_iam_role)
**The Identity Provider.** Handles secure image storage and CI/CD trust relationships.
*   **The Innovation:** Automated ECR lifecycle policies and OIDC trust configurations.
*   **Impact:** Ensures image immutability and automated cleanup of obsolete tags to minimize S3 storage costs.

---

## 💎 Engineering Excellence
*   **Zero-Cost for Development:** Optimized to run with minimal resources (single NAT, no-domain mode) while being 100% ready for a Production-grade SSL/Multi-AZ setup.
*   **Environment Consistency:** All modules use a unified tagging system and remote state integration to prevent "Environment Drift."
*   **Idempotency:** Advanced use of Terraform DSL ensures stable `plan` and `apply` cycles even during complex infrastructure migrations.

---
**Author's Note:**
"This repository represents my journey in mastering **Infrastructure as Code**. I don't just provision resources; I design systems that save company budget and developer time. Every line of code here is written with a deep understanding of how the AWS cloud works 'under the hood'."
