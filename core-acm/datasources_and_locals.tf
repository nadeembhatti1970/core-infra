# --------------------------------------------------------------------
# Local values used throughout the ACM configuration
# --------------------------------------------------------------------
locals {
  # Business division or team name (from variable)
  owners = var.business_division

  # Environment name such as dev, staging, prod (from variable)
  environment = var.environment_name

  # Standardized naming prefix: "<division>-<env>"
  name = "${local.owners}-${local.environment}"

  # Hosted zone from core-route53
  zone_id   = data.terraform_remote_state.route53.outputs.zone_id
  zone_name = data.terraform_remote_state.route53.outputs.zone_name

  # Fully-qualified SANs, e.g. "*" => "*.bizopensource.com"
  subject_alternative_names = [for n in var.subject_alternative_names : "${n}.${local.zone_name}"]

  # Every name on the certificate (apex + SANs)
  certificate_domains = concat([local.zone_name], local.subject_alternative_names)

  # ACM validation details indexed by domain name
  domain_validation_options = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => dvo
  }
}
