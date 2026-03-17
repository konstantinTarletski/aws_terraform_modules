# 🚀 Smart ALB & SSL Automation Module (Terraform)

> **Architectural Note:** This module is an original, custom-built solution developed during an in-depth Terraform study. I deliberately avoided using public third-party modules (like `terraform-aws-modules`) to implement proprietary resource management logic and ensure granular control over every AWS infrastructure component.

## 🏛 Architectural Design & Problem Solving

The module is engineered to deploy an **Application Load Balancer (ALB)** capable of dynamically adapting to complex microservices topologies. The core objective is to provide consistent traffic routing to API services without requiring configuration changes within the applications themselves.

### Solving the Context Path Constraint
A standard AWS ALB (Layer 7) does not natively support URL Path Rewrite (e.g., stripping a `/api/` prefix before forwarding the request). This often causes issues where prefixes are passed into the container, breaking internal API links, static assets, and auto-generated documentation.

This module provides two systemic strategies to bypass this limitation while maintaining request "purity" for the target application:

## ⚙️ Operational Modes

### 1. Port-Based Routing
Activated when no delegated domain is provided (`existing_domain_name = null`).
*   **Logic:** The module dynamically provisions ALB Listeners corresponding directly to the service ports.
*   **Outcome:** Requests to `http://alb-dns-name:8080/` reach the application root (`/`). This ensures that **API interfaces** and their documentation remain stable and accessible without path distortion.
*   **Multi-Port Support:** Purposefully designed to support **multiple ports for a single application** (e.g., main traffic on 8080 + monitoring/metrics on 9090) to handle complex interaction scenarios.

### 2. Host-Based Routing
Activated by providing an `existing_domain_name`.
*   **SSL/TLS Termination:** Full automation of **ACM** certificate lifecycles, including issuance and DNS-01 validation via Route53.
*   **Traffic Enforcement:** Automatically configures **301 Redirects** for all incoming HTTP ports to a secured **443 (HTTPS)** listener.
*   **Service Discovery:** Traffic is distributed via subdomains (e.g., `api.domain.com`) while preserving the original path structure.


## 📦 Integration Example

```hcl
## 📦 Real-World Integration Example

This example demonstrates how to integrate the module with existing infrastructure components using **Terraform Remote State**.

```hcl
module "dev_alb" {
  source       = "git@github.com:konstantinTarletski/aws_terraform_modules.git//alb_and_ssl?ref=v2.0.0"
  
  # Context from Global Variables & Network state
  project_name = data.terraform_remote_state.shared.outputs.project_name
  environment  = data.terraform_remote_state.globalvars.outputs.environment
  default_tags = data.terraform_remote_state.globalvars.outputs.default_tags
  vpc_id       = data.terraform_remote_state.network.outputs.vpc_id
  subnets_ids  = data.terraform_remote_state.network.outputs.public_subnets_ids

  # Domain Management (Uncomment to enable SSL/Route53/ACM)
  # existing_domain_name = "tarlekon.click"

  # Dynamic Port Mapping Logic
  # Mode A (HTTP): Maps ALB:8815 -> Target:8815
  # Mode B (HTTPS): Maps game-sys.tarlekon.click:443 -> Target:8815
  alb_port_mappings = { 
    "8815" = { 
      host         = "game-sys", 
      priority     = 10, 
      health_check = "/swagger-ui.html" 
    } 
  }

  # Advanced Security Group Configuration
  # Allows full control over ingress/egress CIDR blocks and specific Security Groups
  alb_sg_ingress_ports_and_cidr = { 
    "80"   = ["0.0.0.0/0"], 
    "443"  = ["0.0.0.0/0"],
    "8815" = ["0.0.0.0/0"] 
  }

  alb_sg_egress_ports_and_cidr = { 
    "8815" = concat(
      [data.terraform_remote_state.network.outputs.vpc_cidr_block],
      data.terraform_remote_state.network.outputs.vpc_secondary_cidr_blocks
    )
  }
}
