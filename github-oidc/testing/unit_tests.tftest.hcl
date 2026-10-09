# --------------------------------------------------------------------
# Unit tests: plan-only against a mocked AWS provider (no credentials needed)
# Focus: OIDC trust boundaries (branch refs -> plan role; main -> apply role)
# and the apply role's self-protection guardrails.
# --------------------------------------------------------------------
mock_provider "aws" {
  override_during = plan

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
}

variables {
  aws_region                 = "eu-west-2"
  environment_name           = "dev"
  business_division          = "devops"
  github_repository          = "nadeembhatti1970/core-infra"
  github_repository_owner_id = "13079239"
  github_repository_id       = "1399975654"
  tfstate_bucket_name        = "tfstate-dev-eu-west-2-8cbztj"
}

run "oidc_provider_targets_github_with_sts_audience" {
  command = plan

  assert {
    condition     = aws_iam_openid_connect_provider.github.url == "https://token.actions.githubusercontent.com"
    error_message = "OIDC provider must use the GitHub Actions issuer URL"
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.github.client_id_list, "sts.amazonaws.com") && length(aws_iam_openid_connect_provider.github.client_id_list) == 1
    error_message = "OIDC provider audience must be sts.amazonaws.com"
  }
}

run "plan_role_trusts_branch_refs_only" {
  command = plan

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.plan_trust.statement[0].condition :
      c.test == "StringLike" && c.variable == "token.actions.githubusercontent.com:sub" && c.values == tolist(["repo:nadeembhatti1970@13079239/core-infra@1399975654:ref:refs/heads/*"])
    ])
    error_message = "Plan role must only trust branch-ref tokens from this repository"
  }

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.plan_trust.statement[0].condition :
      c.variable == "token.actions.githubusercontent.com:aud" && c.values == tolist(["sts.amazonaws.com"])
    ])
    error_message = "Plan role trust must pin the sts.amazonaws.com audience"
  }

  assert {
    condition = alltrue(flatten([
      for c in data.aws_iam_policy_document.plan_trust.statement[0].condition : [
        for v in c.values : !strcontains(v, "pull_request")
      ]
    ]))
    error_message = "Plan role trust must not include pull_request subjects"
  }
}

run "apply_role_trusts_only_main_branch" {
  command = plan

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.apply_trust.statement[0].condition :
      c.test == "StringEquals" && c.variable == "token.actions.githubusercontent.com:sub" && c.values == tolist(["repo:nadeembhatti1970@13079239/core-infra@1399975654:ref:refs/heads/main"])
    ])
    error_message = "Apply role must only trust the main branch (exact match, no wildcards)"
  }

  assert {
    condition = alltrue(flatten([
      for c in data.aws_iam_policy_document.apply_trust.statement[0].condition : [
        for v in c.values : !strcontains(v, "*")
      ]
    ]))
    error_message = "Apply role trust must not contain wildcards"
  }

  assert {
    condition = alltrue(flatten([
      for c in data.aws_iam_policy_document.apply_trust.statement[0].condition : [
        for v in c.values : !strcontains(v, "pull_request")
      ]
    ]))
    error_message = "Apply role trust must not include pull_request subjects"
  }
}

run "plan_role_is_read_only_with_state_locking" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.plan_readonly.policy_arn == "arn:aws:iam::aws:policy/ReadOnlyAccess"
    error_message = "Plan role must use the AWS managed ReadOnlyAccess policy"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.plan_state.statement :
      s.sid == "ManageStateLockFiles" && s.resources == toset(["arn:aws:s3:::tfstate-dev-eu-west-2-8cbztj/*.tflock"])
    ])
    error_message = "Plan role may only write *.tflock objects in the state bucket"
  }
}

run "apply_role_cannot_modify_bootstrap_or_state_bucket" {
  command = plan

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.apply.statement :
      s.sid == "DenyBootstrapIdentityChanges" && s.effect == "Deny" && contains(s.resources, "arn:aws:iam::111122223333:role/devops-dev-gha-*")
    ])
    error_message = "Apply role must be denied IAM changes to the gha-* bootstrap roles"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.apply.statement :
      s.sid == "DenyStateBucketChanges" && s.effect == "Deny" && contains(s.actions, "s3:DeleteBucket")
    ])
    error_message = "Apply role must be denied from deleting or reconfiguring the state bucket"
  }
}

run "apply_role_can_discover_tagged_controller_resources" {
  command = plan

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.apply.statement :
      s.sid == "DiscoverControllerManagedResources" && contains(s.actions, "tag:GetResources") && s.resources == toset(["*"])
    ])
    error_message = "Apply role must discover tagged load balancers during teardown"
  }
}

run "role_names_and_session_follow_conventions" {
  command = plan

  assert {
    condition     = aws_iam_role.plan.name == "devops-dev-gha-terraform-plan" && aws_iam_role.apply.name == "devops-dev-gha-terraform-apply"
    error_message = "Role names must be <division>-<env>-gha-terraform-{plan,apply}"
  }

  assert {
    condition     = aws_iam_role.apply.max_session_duration == 7200
    error_message = "Apply role session must allow 2 hours for EKS create/destroy"
  }
}

run "apply_branch_is_configurable" {
  command = plan

  variables {
    apply_branch = "release"
  }

  assert {
    condition = anytrue([
      for c in data.aws_iam_policy_document.apply_trust.statement[0].condition :
      c.variable == "token.actions.githubusercontent.com:sub" && c.values == tolist(["repo:nadeembhatti1970@13079239/core-infra@1399975654:ref:refs/heads/release"])
    ])
    error_message = "Apply role trust must follow var.apply_branch"
  }
}

run "rejects_invalid_repository_format" {
  command = plan

  variables {
    github_repository = "not-a-repo"
  }

  expect_failures = [var.github_repository]
}

run "rejects_session_duration_out_of_range" {
  command = plan

  variables {
    max_session_duration = 600
  }

  expect_failures = [var.max_session_duration]
}
