##############################################
# Outputs
##############################################
output "certificate_arn" {
  description = "ARN of the validated ACM certificate (use in alb.ingress.kubernetes.io/certificate-arn)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "certificate_domains" {
  description = "Domains covered by the certificate"
  value       = concat([aws_acm_certificate.main.domain_name], tolist(aws_acm_certificate.main.subject_alternative_names))
}
