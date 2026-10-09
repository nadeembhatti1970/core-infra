# --------------------------------------------------------------------
# Integration tests: ephemeral apply against a mocked AWS provider.
# Exercises the validation wait and outputs without touching AWS.
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

  mock_resource "aws_acm_certificate_validation" {
    defaults = {
      certificate_arn = "arn:aws:acm:eu-west-2:111122223333:certificate/00000000-0000-0000-0000-000000000000"
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

run "apply_outputs_validated_certificate" {
  command = apply

  assert {
    condition     = output.certificate_arn == "arn:aws:acm:eu-west-2:111122223333:certificate/00000000-0000-0000-0000-000000000000"
    error_message = "certificate_arn output must come from the validated certificate"
  }

  assert {
    condition     = contains(output.certificate_domains, "bizopensource.com") && contains(output.certificate_domains, "*.bizopensource.com")
    error_message = "certificate_domains output must list apex and wildcard"
  }

  assert {
    condition     = length(aws_route53_record.acm_validation) == 2
    error_message = "One validation record resource per certificate domain is expected"
  }
}
