# --------------------------------------------------------------------
# Reference the Remote State from Route53 Project
# --------------------------------------------------------------------
data "terraform_remote_state" "route53" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"  # Name of the remote S3 bucket where the Route53 state is stored
    key    = "route53/dev/terraform.tfstate" # Path to the Route53 tfstate file within the bucket
    region = var.aws_region                  # Region where the S3 bucket exists
  }
}
