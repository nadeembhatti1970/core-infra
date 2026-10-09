# --------------------------------------------------------------------
# Data sources and local values for the GitHub OIDC configuration
# --------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  # Business division or team name (from variable)
  owners = var.business_division

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}"

  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  # GitHub OIDC issuer (without scheme) used in trust policy condition keys
  github_oidc_host = "token.actions.githubusercontent.com"

  # Role names; the apply role is denied from modifying anything matching local.protected_role_pattern
  plan_role_name         = "${local.name}-gha-terraform-plan"
  apply_role_name        = "${local.name}-gha-terraform-apply"
  protected_role_pattern = "arn:${local.partition}:iam::${local.account_id}:role/${local.name}-gha-*"

  tfstate_bucket_arn = "arn:${local.partition}:s3:::${var.tfstate_bucket_name}"

  common_tags = merge(var.tags, {
    Environment = local.environment
    Project     = local.name
    Component   = "GitHub Actions OIDC"
  })
}
