##############################################
# Public ACM Certificate (DNS validated)
##############################################
# checkov:skip=CKV2_AWS_71:Wildcard SAN is required to cover first-level subdomains used by ingress hosts.
resource "aws_acm_certificate" "main" {
  domain_name               = local.zone_name
  subject_alternative_names = local.subject_alternative_names
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name        = local.zone_name
    Environment = local.environment
    Project     = local.name
  })

  lifecycle {
    create_before_destroy = true
  }
}

##############################################
# DNS Validation Records in Route53
# The apex and wildcard share one validation CNAME, hence allow_overwrite.
# Keyed on the configured domain names so for_each is known at plan time.
##############################################
resource "aws_route53_record" "acm_validation" {
  for_each = toset(local.certificate_domains)

  allow_overwrite = true
  zone_id         = local.zone_id
  name            = local.domain_validation_options[each.key].resource_record_name
  type            = local.domain_validation_options[each.key].resource_record_type
  records         = [local.domain_validation_options[each.key].resource_record_value]
  ttl             = 60
}

##############################################
# Wait for the certificate to be issued
# Requires the IONOS name servers to point at the Route53 zone.
##############################################
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
