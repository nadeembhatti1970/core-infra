# --------------------------------------------------------------------
# Local values used throughout the Route53 configuration
# --------------------------------------------------------------------
locals {
  # Business division or team name (from variable)
  owners = var.business_division

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}"
}
