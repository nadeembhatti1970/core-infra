# --------------------------------------------------------------------
# Reference the Remote State from the GitHub OIDC bootstrap project
# Provides the CI plan role ARN that needs read-only cluster access.
# --------------------------------------------------------------------
data "terraform_remote_state" "github_oidc" {
  backend = "s3"

  config = {
    bucket = "tfstate-dev-eu-west-2-8cbztj"      # Name of the remote S3 bucket where the state is stored
    key    = "github-oidc/dev/terraform.tfstate" # Path to the GitHub OIDC tfstate file within the bucket
    region = var.aws_region                      # Region where the S3 bucket exists
  }
}
