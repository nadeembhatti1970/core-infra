terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
  # Remote Backend
  backend "s3" {
    bucket       = "tfstate-dev-eu-west-2-8cbztj"
    key          = "vpc/dev/terraform.tfstate"
    region       = "eu-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  # core-eks adds kubernetes.io/* tags to these subnets (eks_tags.tf) for the
  # AWS Load Balancer Controller and Karpenter; don't strip them on apply.
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}