data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"
    key    = "eks/${var.environment_name}/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "route53" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"
    key    = "route53/${var.environment_name}/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "acm" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"
    key    = "acm/${var.environment_name}/terraform.tfstate"
    region = var.aws_region
  }
}
