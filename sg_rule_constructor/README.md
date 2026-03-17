# 🛠️ Security Group Rule Constructor (Logic Decoupler)

> **Architectural Note:** This module is an original, custom-built solution developed during an in-depth Terraform study. I deliberately avoided using public third-party modules (like `terraform-aws-modules`) to implement proprietary resource management logic and ensure granular control over every AWS infrastructure component.

## 🏛 Architectural Concept
The module acts as a specialized **orchestrator** for Security Group rules. Its primary mission is to decouple networking logic from the Security Group resource creation, effectively eliminating the common **Circular Dependency** (Deadlock) issue in Terraform.

## 🏗 Key Features

### 1. Solving Circular Dependencies
In complex microservices topologies (e.g., ALB <-> ECS), two groups often need to reference each other's IDs.
*   **The Solution:** By using standalone `aws_security_group_rule` resources instead of inline blocks, this module allows you to provision empty Security Groups first and then "inject" rules in any order, preventing infrastructure deployment locks.

### 2. Named Rules for Port Overlapping
Standard maps in Terraform use the **Port** as a key, which prevents creating multiple rules for the same port.
*   **The Innovation:** I implemented `*_named` variables (e.g., `ingress_ports_and_sg_named`). This allows users to provide unique logical names for rules while using duplicate ports.
*   **Example:** You can have `rule_from_alb` and `rule_from_vpn` both pointing to port `8080` without any map key conflicts.

### 3. Universal Interface (4-Way Logic)
The constructor handles all possible traffic scenarios in a single interface:
*   **Ingress/Egress from SGs**: For internal service-to-service communication.
*   **Ingress/Egress from CIDR**: For external access or VPC-wide routing.

## 🛠 Engineering Excellence

*   **Logic Decoupling:** Centralizes all firewall logic in one place, making auditing and troubleshooting much easier.
*   **Granular Control:** Every rule is an individual AWS resource. This increases transparency in the AWS Console and improves the precision of `terraform plan` outputs.
*   **Input Flexibility:** Supports both simple Port-to-List mappings and advanced Named-Object structures for complex requirements.

## 📦 Integration Example

```hcl
module "ecs_security_rules" {
  source            = "git@github.com:konstantinTarletski/aws_terraform_modules.git//sg_rule_constructor?ref=v1.4.0"
  security_group_id = aws_security_group.app_sg.id

  # Standard Mapping (Key = Port)
  ingress_ports_and_sg = {
    "8815" = [module.alb.alb_sg_id]
  }

  # Named Mapping (Key = Logical Name, allows duplicate ports)
  ingress_ports_and_sg_named = {
    "api_access"   = { port = "8080", sg_id = "sg-12345" }
    "admin_access" = { port = "8080", sg_id = "sg-67890" }
  }
}
