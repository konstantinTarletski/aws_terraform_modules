# 🌐 High-Availability Multi-Tier VPC Module

> **Architectural Note:** This module is an original, custom-built solution developed during an in-depth Terraform study. I deliberately avoided using public third-party modules (like `terraform-aws-modules`) to implement proprietary resource management logic and ensure granular control over every AWS infrastructure component.

## 🏛 Architectural Concept
This module implements a core AWS networking foundation based on a **Three-Tier Topology**. It is designed as an intelligent constructor that analyzes input data to automatically build an optimal routing map, balancing high availability (HA) with cost efficiency.

## 🏗 Key Features

### 1. Three-Tier Segmentation (Public / Private / DB)
The infrastructure is strictly divided into functional tiers to ensure maximum security:
*   **Public Subnets**: Ingress points for ALBs and NAT Gateways. The only segment with direct internet access.
*   **Private Subnets**: Main tier for application workloads (ECS Tasks, microservices). Accessible only from the public segment.
*   **DB Subnets**: Isolated tier for databases (RDS, NoSQL), accessible exclusively from the private application segment.

### 2. Scalable Distribution (Subnets > AZs)
The module supports an arbitrary number of subnets for each tier, **independent of the number of Availability Zones (AZs)** in the region.
*   **Logic:** If the number of subnets exceeds the available AZs, the module automatically distributes them across all zones using a **circular (modulo) logic**. This ensures an even infrastructure spread across AWS data centers regardless of the network slicing requirements.

### 3. Intelligent NAT Controller & Routing (Cost Optimization)
I implemented advanced logic to manage NAT Gateways that "sees" the network topology and prevents unnecessary AWS charges:
*   **Zero-NAT Logic:** If no private subnets are defined in the configuration, the module **will not provision** any NAT Gateways. No consumers = no costs.
*   **Smart Unique NAT:** The module tracks zone uniqueness. Even if multiple public subnets are created within the same AZ, the module intelligently provisions **only one NAT Gateway** per zone to avoid redundant resource billing.
*   **Self-Healing Cross-Zone Routing:** This is a key architectural highlight. If private resources exist in a specific AZ but **no public subnet with a NAT Gateway** is available in that same zone, the module automatically identifies a NAT in a **neighboring AZ** and maps the route through it. This ensures connectivity even with asymmetrical network topologies.
*   **Adaptability (DEV vs. PROD):**
  *   *Cost Savings:* Create only 1 public subnet for the entire region — the module provisions 1 NAT and automatically routes all private tiers across all AZs through it.
  *   *High Availability:* Create public subnets in every AZ — the module provisions 1 NAT per zone, enabling local routing for minimal latency and maximum fault tolerance.

## 🛠 Technical Implementation

*   **Regional Portability:** Automatically queries available AZs via `data.aws_availability_zones`, making the module portable across any AWS region (Frankfurt, Virginia, Ireland, etc.).
*   **CIDR Management:** Leverages `cidrsubnet` functions to eliminate human error and IP address overlaps when scaling network tiers.
*   **Isolated Routing Tables:** Each AZ is assigned its own Route Table, localizing traffic within the zone and increasing overall system resiliency.

## 📦 Usage Example

## 📦 Integration Example

This example demonstrates how to deploy the network foundation for a **Multi-AZ Application Load Balancer** setup, retrieving global context from a remote state.

```hcl
module "dev_network" {
  source      = "git@github.com:konstantinTarletski/aws_terraform_modules.git//network
  environment = "dev"
  
  # VPC Global CIDR is 10.0.0.0/16 by default
  # To ensure High Availability (HA) for ALB, we provision at least 2 Public Subnets
  public_subnets_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]

  # Tier Customization:
  # Private subnets fall back to defaults (e.g., ["10.0.101.0/24"])
  # DB tier is explicitly disabled for this environment to save costs
  db_subnets_cidrs = []

  # Global Metadata
  default_tags = data.terraform_remote_state.globalvars.outputs.default_tags
}
