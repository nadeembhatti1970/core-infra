# --------------------------------------------------------------------
# Integration tests: ephemeral apply against a mocked AWS provider.
# Exercises computed attributes and outputs without touching AWS.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_resource "aws_route53_zone" {
    defaults = {
      zone_id      = "Z0123456789ABCDEFGHIJ"
      name_servers = ["ns-1.awsdns-01.org", "ns-2.awsdns-02.co.uk", "ns-3.awsdns-03.com", "ns-4.awsdns-04.net"]
    }
  }
}

variables {
  domain_name = "bizopensource.com"
}

run "apply_exposes_outputs_for_core_acm" {
  command = apply

  assert {
    condition     = output.zone_id == "Z0123456789ABCDEFGHIJ"
    error_message = "zone_id output must expose the hosted zone ID"
  }

  assert {
    condition     = output.zone_name == "bizopensource.com"
    error_message = "zone_name output must expose the hosted zone name"
  }

  assert {
    condition     = length(output.name_servers) == 4
    error_message = "name_servers output must list the 4 delegation name servers for IONOS"
  }
}
