# --------------------------------------------------------------------
# Integration tests: ephemeral apply against a mocked AWS provider.
# Exercises outputs consumed by core-eks and the GitHub repo variables.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_iam_openid_connect_provider" {
    defaults = {
      arn = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/devops-dev-gha-terraform-apply-policy"
    }
  }
}

run "apply_exposes_role_arns" {
  command = apply

  override_resource {
    target = aws_iam_role.plan
    values = {
      arn = "arn:aws:iam::111122223333:role/devops-dev-gha-terraform-plan"
    }
  }

  override_resource {
    target = aws_iam_role.apply
    values = {
      arn = "arn:aws:iam::111122223333:role/devops-dev-gha-terraform-apply"
    }
  }

  assert {
    condition     = output.plan_role_arn == "arn:aws:iam::111122223333:role/devops-dev-gha-terraform-plan"
    error_message = "plan_role_arn output must expose the plan role ARN"
  }

  assert {
    condition     = output.apply_role_arn == "arn:aws:iam::111122223333:role/devops-dev-gha-terraform-apply"
    error_message = "apply_role_arn output must expose the apply role ARN"
  }

  assert {
    condition     = output.github_oidc_provider_arn == "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    error_message = "github_oidc_provider_arn output must expose the provider ARN"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.apply.role == "devops-dev-gha-terraform-apply"
    error_message = "Apply policy must be attached to the apply role"
  }
}
