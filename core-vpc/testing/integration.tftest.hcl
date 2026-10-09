# --------------------------------------------------------------------
# Integration tests: ephemeral apply against a mocked AWS provider.
# Exercises computed IDs and the outputs consumed via remote state by
# core-eks, core-eks-telemetry and core-eks-karpenter without touching AWS.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    }
  }

  mock_resource "aws_vpc" {
    defaults = {
      id = "vpc-0123456789abcdef0"
    }
  }
}

variables {
  aws_region       = "eu-west-2"
  environment_name = "dev"
  vpc_cidr         = "10.0.0.0/16"
  subnet_newbits   = 8
}

run "apply_exposes_outputs_for_remote_state_consumers" {
  command = apply

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0"
    error_message = "vpc_id output must expose the VPC ID"
  }

  assert {
    condition     = length(output.private_subnet_ids) == 3 && length(output.public_subnet_ids) == 3
    error_message = "private_subnet_ids and public_subnet_ids outputs must each list 3 subnets"
  }

  assert {
    condition     = toset(values(output.public_subnet_map)) == toset(output.public_subnet_ids)
    error_message = "public_subnet_map and public_subnet_ids outputs must describe the same public subnets"
  }

  assert {
    condition     = length(setintersection(toset(output.private_subnet_ids), toset(output.public_subnet_ids))) == 0
    error_message = "Public and private subnet ID outputs must not overlap"
  }

  assert {
    condition     = toset(keys(output.public_subnet_map)) == toset(["eu-west-2a", "eu-west-2b", "eu-west-2c"])
    error_message = "public_subnet_map output must be keyed by AZ"
  }
}

run "apply_wires_nat_gateway_and_routes" {
  command = apply

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = contains(output.public_subnet_ids, aws_nat_gateway.nat.subnet_id)
    error_message = "NAT gateway must be placed in a public subnet"
  }

  assert {
    condition     = aws_nat_gateway.nat.allocation_id == aws_eip.nat.id
    error_message = "NAT gateway must use the dedicated EIP"
  }

  assert {
    condition     = one(aws_route_table.public_rt.route).gateway_id == aws_internet_gateway.igw.id
    error_message = "Public route table default route must target the internet gateway"
  }

  assert {
    condition     = one(aws_route_table.private_rt.route).nat_gateway_id == aws_nat_gateway.nat.id
    error_message = "Private route table default route must target the NAT gateway"
  }

  assert {
    condition     = length(aws_default_security_group.default.ingress) == 0 && length(aws_default_security_group.default.egress) == 0
    error_message = "VPC default security group must have no ingress or egress rules (CKV2_AWS_12)"
  }

  assert {
    condition     = aws_default_security_group.default.vpc_id == output.vpc_id
    error_message = "Locked-down default security group must belong to the managed VPC"
  }
}
