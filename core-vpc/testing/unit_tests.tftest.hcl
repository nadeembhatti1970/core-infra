# --------------------------------------------------------------------
# Unit tests: plan-only against a mocked AWS provider (no credentials needed)
# The availability zone lookup is mocked with the three eu-west-2 AZs.
# Each run targets the local ./modules/vpc module directly so that its
# internal resources (VPC, subnets, NAT, route tables) can be asserted on;
# root-level assertions can only see the module's outputs.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    }
  }
}

variables {
  environment_name = "dev"
  vpc_cidr         = "10.0.0.0/16"
  subnet_newbits   = 8
  tags = {
    Terraform = "true"
  }
}

run "vpc_uses_cidr_and_enables_dns" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
    error_message = "VPC CIDR block must equal var.vpc_cidr"
  }

  assert {
    condition     = aws_vpc.main.enable_dns_support && aws_vpc.main.enable_dns_hostnames
    error_message = "VPC must enable DNS support and DNS hostnames (required by EKS and private endpoints)"
  }

  assert {
    condition     = aws_vpc.main.tags["Name"] == "dev-vpc" && aws_vpc.main.tags["Terraform"] == "true"
    error_message = "VPC must be named <environment_name>-vpc and carry the merged var.tags"
  }
}

run "public_subnets_span_three_azs_with_expected_cidrs" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = length(aws_subnet.public) == 3
    error_message = "Exactly one public subnet per AZ (3) is expected"
  }

  assert {
    condition     = toset(keys(aws_subnet.public)) == toset(["eu-west-2a", "eu-west-2b", "eu-west-2c"])
    error_message = "Public subnets must be keyed by, and placed in, the first three available AZs"
  }

  assert {
    condition = (
      aws_subnet.public["eu-west-2a"].cidr_block == "10.0.0.0/24" &&
      aws_subnet.public["eu-west-2b"].cidr_block == "10.0.1.0/24" &&
      aws_subnet.public["eu-west-2c"].cidr_block == "10.0.2.0/24"
    )
    error_message = "Public subnet CIDRs must be 10.0.0.0/24, 10.0.1.0/24 and 10.0.2.0/24"
  }

  assert {
    condition     = alltrue([for az, s in aws_subnet.public : s.availability_zone == az && s.map_public_ip_on_launch])
    error_message = "Each public subnet must live in its keyed AZ and map public IPs on launch"
  }
}

run "private_subnets_span_three_azs_with_expected_cidrs" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = length(aws_subnet.private) == 3
    error_message = "Exactly one private subnet per AZ (3) is expected"
  }

  assert {
    condition = (
      aws_subnet.private["eu-west-2a"].cidr_block == "10.0.10.0/24" &&
      aws_subnet.private["eu-west-2b"].cidr_block == "10.0.11.0/24" &&
      aws_subnet.private["eu-west-2c"].cidr_block == "10.0.12.0/24"
    )
    error_message = "Private subnet CIDRs must be 10.0.10.0/24, 10.0.11.0/24 and 10.0.12.0/24"
  }

  assert {
    condition     = alltrue([for az, s in aws_subnet.private : s.availability_zone == az && s.map_public_ip_on_launch != true])
    error_message = "Each private subnet must live in its keyed AZ and must not map public IPs"
  }

  assert {
    condition     = aws_subnet.private["eu-west-2a"].tags["Name"] == "dev-private-eu-west-2a"
    error_message = "Private subnets must be named <environment_name>-private-<az>"
  }
}

run "route_tables_send_default_route_via_igw_and_nat" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = length(aws_route_table.public_rt.route) == 1 && one(aws_route_table.public_rt.route).cidr_block == "0.0.0.0/0"
    error_message = "Public route table must have a single 0.0.0.0/0 route (to the internet gateway)"
  }

  assert {
    condition     = length(aws_route_table.private_rt.route) == 1 && one(aws_route_table.private_rt.route).cidr_block == "0.0.0.0/0"
    error_message = "Private route table must have a single 0.0.0.0/0 route (to the NAT gateway)"
  }

  assert {
    condition     = length(aws_route_table_association.public_rt_assoc) == 3 && length(aws_route_table_association.private_rt_assoc) == 3
    error_message = "Every public and private subnet must be associated with its route table"
  }
}

run "nat_gateway_and_eip_are_single_and_tagged" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = aws_nat_gateway.nat.tags["Name"] == "dev-nat" && aws_eip.nat.tags["Name"] == "dev-nat-eip"
    error_message = "NAT gateway and its EIP must be named <environment_name>-nat / <environment_name>-nat-eip"
  }

  assert {
    condition     = aws_internet_gateway.igw.tags["Name"] == "dev-igw"
    error_message = "Internet gateway must be named <environment_name>-igw"
  }
}

run "default_security_group_is_adopted_and_tagged" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  assert {
    condition     = aws_default_security_group.default.tags["Name"] == "dev-default-sg"
    error_message = "Default security group must be named <environment_name>-default-sg"
  }
}

run "custom_cidr_and_newbits_reshape_subnets" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  variables {
    environment_name = "prod"
    vpc_cidr         = "172.16.0.0/20"
    subnet_newbits   = 4
  }

  assert {
    condition     = aws_vpc.main.cidr_block == "172.16.0.0/20" && aws_vpc.main.tags["Name"] == "prod-vpc"
    error_message = "VPC CIDR and Name tag must follow input variables"
  }

  assert {
    condition     = toset([for s in aws_subnet.public : s.cidr_block]) == toset(["172.16.0.0/24", "172.16.1.0/24", "172.16.2.0/24"])
    error_message = "Public subnets must be carved from var.vpc_cidr using var.subnet_newbits (netnums 0-2)"
  }

  assert {
    condition     = toset([for s in aws_subnet.private : s.cidr_block]) == toset(["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"])
    error_message = "Private subnets must be carved from var.vpc_cidr using var.subnet_newbits (netnums 10-12)"
  }
}

run "extra_availability_zones_are_capped_at_three" {
  command = plan

  module {
    source = "./modules/vpc"
  }

  override_data {
    target = data.aws_availability_zones.available
    values = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c", "eu-west-2d"]
    }
  }

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3
    error_message = "Subnet count must stay at 3 per tier even if AWS adds an Availability Zone"
  }

  assert {
    condition     = !contains(keys(aws_subnet.private), "eu-west-2d")
    error_message = "A newly added fourth AZ must not receive subnets"
  }
}
