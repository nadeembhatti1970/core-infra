##############################################
# Outputs (consumed by core-acm via remote state)
##############################################
output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone domain name"
  value       = aws_route53_zone.main.name
}

output "name_servers" {
  description = "Name servers to configure at IONOS for the domain"
  value       = aws_route53_zone.main.name_servers
}
