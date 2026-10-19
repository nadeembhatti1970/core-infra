# VPC module

Internal Terraform module used by [`core-vpc`](../../README.md). It creates a
VPC, public and private subnets in three available Availability Zones,
an Internet Gateway, and one NAT Gateway shared by the private subnets. The
NAT Gateway is placed in the first public subnet; the public subnets route
through the Internet Gateway and the private subnets route through the NAT
Gateway.

## Usage

The module is consumed locally by the `core-vpc` root module:

```hcl
module "vpc" {
  source           = "./modules/vpc"
  environment_name = var.environment_name
  vpc_cidr         = var.vpc_cidr
  subnet_newbits   = var.subnet_newbits
  tags             = var.tags
}
```

## Inputs

| Name | Description | Default |
| --- | --- | --- |
| `environment_name` | Environment name used in resource names and tags | `"dev"` |
| `vpc_cidr` | VPC IPv4 CIDR block | `"10.0.0.0/16"` |
| `subnet_newbits` | Additional CIDR bits used for each subnet | `8` |
| `tags` | Tags applied to module resources | `{ Terraform = "true" }` |

With the default `/16` VPC and `subnet_newbits = 8`, the module creates `/24`
subnets. Public subnet indices begin at zero; private subnet indices begin at
10. Ensure the VPC CIDR has enough non-overlapping space for both sets.

## Outputs

| Name | Description |
| --- | --- |
| `vpc_id` | Created VPC ID |
| `public_subnet_ids` | Public subnet IDs |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_map` | Public subnet IDs keyed by Availability Zone |

The single-NAT layout is intended for cost-conscious environments. It is not
multi-AZ resilient for private-subnet egress and the NAT Gateway incurs
ongoing charges.
