# --------------------------------------------------------------------
# Unit tests: plan-only against a mocked AWS provider (no credentials needed)
# The core-route53 remote state is overridden with a fixed hosted zone.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:eu-west-2:111122223333:certificate/00000000-0000-0000-0000-000000000000"
      domain_validation_options = [
        {
          domain_name           = "bizopensource.com"
          resource_record_name  = "_abc123.bizopensource.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
        {
          domain_name           = "*.bizopensource.com"
          resource_record_name  = "_abc123.bizopensource.com."
          resource_record_type  = "CNAME"
          resource_record_value = "_def456.acm-validations.aws."
        },
      ]
    }
  }
}

override_data {
  target = data.terraform_remote_state.route53
  values = {
    outputs = {
      zone_id   = "Z0123456789ABCDEFGHIJ"
      zone_name = "bizopensource.com"
    }
  }
}

variables {
  aws_region                = "eu-west-2"
  environment_name          = "dev"
  business_division         = "devops"
  subject_alternative_names = ["*"]
}

run "certificate_covers_apex_and_wildcard" {
  command = plan

  assert {
    condition     = aws_acm_certificate.main.domain_name == "bizopensource.com"
    error_message = "Certificate primary name must be the hosted zone apex"
  }

  assert {
    condition     = contains(aws_acm_certificate.main.subject_alternative_names, "*.bizopensource.com")
    error_message = "Certificate must include the wildcard SAN covering sftpgo.bizopensource.com"
  }
}

run "certificate_uses_dns_validation" {
  command = plan

  assert {
    condition     = aws_acm_certificate.main.validation_method == "DNS"
    error_message = "Certificate must be DNS validated so Route53 can issue/renew it automatically"
  }
}

run "validation_records_target_route53_zone" {
  command = plan

  assert {
    condition     = alltrue([for r in aws_route53_record.acm_validation : r.zone_id == "Z0123456789ABCDEFGHIJ"])
    error_message = "Validation records must be created in the core-route53 hosted zone"
  }

  assert {
    condition     = alltrue([for r in aws_route53_record.acm_validation : r.allow_overwrite])
    error_message = "Validation records must allow overwrite (apex and wildcard share one CNAME)"
  }
}

run "extra_sans_are_qualified_with_zone" {
  command = plan

  variables {
    subject_alternative_names = ["*", "sftpgo"]
  }

  assert {
    condition     = toset(aws_acm_certificate.main.subject_alternative_names) == toset(["*.bizopensource.com", "sftpgo.bizopensource.com"])
    error_message = "Each SAN must be suffixed with the zone name"
  }
}
