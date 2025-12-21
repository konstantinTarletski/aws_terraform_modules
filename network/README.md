# Network Terraform module

Terraform module for creating a flexible AWS VPC network with **three types of subnets** and **smart NAT Gateway placement**.

## Features

- Creates **3 network tiers**:
    - **Public subnets** — direct Internet access (IGW)
    - **Private subnets** — Internet access via NAT Gateway
    - **DB subnets** — fully isolated, no Internet access
- Supports **any number of subnets**, even **more than available AZs**
- **Smart NAT Gateway logic**:
    - One NAT per required Availability Zone
    - NAT is created **only if private subnets exist**
    - If no matching AZ is found — reuses the first available NAT
- Fully AZ-aware routing
- Workspace-aware naming
- Clean outputs grouped by Availability Zone

## Usage

```hcl
module "dev-network" {
  source      = "git@github.com:konstantinTarletski/aws_terraform_modules.git//network"
  environment = "dev"
  vpc_cidr = "10.0.0.0/16"
  public_subnets_cidrs = ["10.0.1.0/24", "10.0.2.0/24",  "10.0.3.0/24"]
  public_subnets_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  public_subnets_cidrs = ["10.0.201.0/24"]
  default_tags = {
    Manufactor = "terraform",
    Design     = "tarlekon",
    Source     = "module"
  }
}
```

## Inputs

| Variable | Description |
|-------|------------|
| `vpc_cidr` | CIDR block for VPC |
| `environment` | Environment name (e.g. dev, prod) |
| `public_subnets_cidrs` | List of CIDRs for public subnets |
| `private_subnets_cidrs` | List of CIDRs for private subnets |
| `db_subnets_cidrs` | List of CIDRs for DB subnets |
| `default_tags` | Default tags applied to all resources |

> Number of subnets **can exceed number of AZs** — module distributes them automatically.

## Outputs

| Output | Description |
|------|------------|
| `vpc_id_and_cidr` | VPC ID and CIDR |
| `public_subnets_ids_and_cidrs` | Public subnets grouped by AZ |
| `private_subnets_ids_and_cidrs` | Private subnets grouped by AZ |
| `db_subnets_ids_and_cidrs` | DB subnets grouped by AZ |
| `nat_subnets_and_zones` | NAT Gateway AZ → subnet mapping |

## Created AWS resources

| Resource | Type |
|-------|------|
| VPC | `aws_vpc` |
| Internet Gateway | `aws_internet_gateway` |
| Public subnets | `aws_subnet` |
| Private subnets | `aws_subnet` |
| DB subnets | `aws_subnet` |
| NAT Gateways | `aws_nat_gateway` |
| Elastic IPs | `aws_eip` |
| Route tables | `aws_route_table` |
| Route associations | `aws_route_table_association` |

## Design notes

- **No hardcoded AZs** — uses `aws_availability_zones`
- **Cost-aware** — minimal number of NAT Gateways
- **Predictable routing** — route tables created per private subnet
- **Safe defaults** — DB layer never gets Internet access

