##############################################
# Public Hosted Zone for the IONOS-registered domain
# After apply, set the domain's name servers at IONOS to the
# values in the "name_servers" output (custom name servers).
##############################################
resource "aws_route53_zone" "main" {
  # checkov:skip=CKV2_AWS_38: DNSSEC needs a DS record at the IONOS registrar and KMS key in us-east-1; deferred until the NS delegation is stable
  # checkov:skip=CKV2_AWS_39: Query logging needs a CloudWatch log group in us-east-1; not required for this public zone
  name    = var.domain_name
  comment = "Public zone for ${var.domain_name} (registrar: IONOS) - managed by Terraform"

  tags = merge(var.tags, {
    Name        = var.domain_name
    Environment = local.environment
    Project     = local.name
  })
}
