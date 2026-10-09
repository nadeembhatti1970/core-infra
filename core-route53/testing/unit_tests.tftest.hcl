# --------------------------------------------------------------------
# Unit tests: plan-only against a mocked AWS provider (no credentials needed)
# --------------------------------------------------------------------
mock_provider "aws" {}

variables {
  aws_region        = "eu-west-2"
  environment_name  = "dev"
  business_division = "devops"
  domain_name       = "bizopensource.com"
}

run "hosted_zone_uses_domain_name" {
  command = plan

  assert {
    condition     = aws_route53_zone.main.name == "bizopensource.com"
    error_message = "Hosted zone name must equal var.domain_name"
  }
}

run "hosted_zone_is_public" {
  command = plan

  assert {
    condition     = length(aws_route53_zone.main.vpc) == 0
    error_message = "Hosted zone must be public (no VPC association) so IONOS can delegate to it"
  }
}

run "hosted_zone_tags_follow_naming_convention" {
  command = plan

  assert {
    condition     = aws_route53_zone.main.tags["Project"] == "devops-dev"
    error_message = "Project tag must be <business_division>-<environment_name>"
  }

  assert {
    condition     = aws_route53_zone.main.tags["Terraform"] == "true"
    error_message = "Default var.tags must be merged into the zone tags"
  }
}

run "hosted_zone_accepts_other_domain" {
  command = plan

  variables {
    domain_name      = "example.org"
    environment_name = "prod"
  }

  assert {
    condition     = aws_route53_zone.main.name == "example.org" && aws_route53_zone.main.tags["Environment"] == "prod"
    error_message = "Zone name and Environment tag must follow input variables"
  }
}
