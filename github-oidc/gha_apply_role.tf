##############################################
# Apply Role: assumed by push / schedule / workflow_dispatch workflows
# on the apply branch (main) only. Manages the services used by the core-infra projects,
# but cannot modify the GitHub OIDC bootstrap or the state bucket itself.
##############################################
data "aws_iam_policy_document" "apply_trust" {
  statement {
    sid     = "GitHubActionsBranches"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Apply branch only (push to main, scheduled teardown, manual runs on main);
    # pull_request tokens and other branch refs cannot assume this role.
    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:sub"
      values   = ["${local.github_oidc_subject_repo}:ref:refs/heads/${var.apply_branch}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  name                 = local.apply_role_name
  description          = "GitHub Actions (${var.apply_branch} branch) - Terraform apply/destroy for ${var.github_repository}"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust.json
  max_session_duration = var.max_session_duration

  tags = merge(local.common_tags, {
    Name = local.apply_role_name
  })
}

data "aws_iam_policy_document" "apply" {
  # checkov:skip=CKV_AWS_107: Deployment role must create IAM roles/policies for EKS, Karpenter, LBC, ExternalDNS and ADOT
  # checkov:skip=CKV_AWS_108: Deployment role reads service data (e.g. SSO, logs) while managing EKS/Grafana
  # checkov:skip=CKV_AWS_109: Deployment role manages IAM and KMS key policies for the provisioned services
  # checkov:skip=CKV_AWS_110: Deployment role creates IAM roles; privilege escalation is bounded by the explicit Deny statements below
  # checkov:skip=CKV_AWS_111: Deployment role creates resources whose ARNs are unknown in advance
  # checkov:skip=CKV_AWS_356: Deployment role creates resources whose ARNs are unknown in advance
  # checkov:skip=CKV2_AWS_40: Full IAM is required to manage service roles; bootstrap roles and the OIDC provider are denied below

  # Services used by core-vpc, core-eks, core-eks-karpenter, core-eks-telemetry, core-route53, core-acm
  statement {
    sid    = "ManageCoreInfraServices"
    effect = "Allow"
    actions = [
      "acm:*",
      "aps:*",
      "autoscaling:*",
      "cloudwatch:*",
      "ec2:*",
      "eks:*",
      "elasticloadbalancing:*",
      "events:*",
      "grafana:*",
      "iam:*",
      "kms:*",
      "logs:*",
      "route53:*",
      "sns:*",
      "sqs:*",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "sts:GetCallerIdentity",
      "xray:*",
    ]
    resources = ["*"]
  }

  # Amazon Managed Grafana with AWS_SSO authentication registers an IAM Identity Center application
  statement {
    sid    = "GrafanaIdentityCenterIntegration"
    effect = "Allow"
    actions = [
      "sso:CreateManagedApplicationInstance",
      "sso:DeleteManagedApplicationInstance",
      "sso:GetManagedApplicationInstance",
      "sso:DescribeRegisteredRegions",
      "sso:GetSharedSsoConfiguration",
      "sso:ListDirectoryAssociations",
      "sso:AssociateProfile",
      "sso:DisassociateProfile",
      "sso:GetProfile",
      "sso:ListProfiles",
      "sso:ListProfileAssociations",
      "organizations:DescribeOrganization",
    ]
    resources = ["*"]
  }

  # Remote state: read/write state objects and lock files
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation", "s3:GetBucketVersioning"]
    resources = [local.tfstate_bucket_arn]
  }

  statement {
    sid       = "ReadWriteState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.tfstate_bucket_arn}/*"]
  }

  # Guardrails: the pipeline must not be able to widen its own access or damage the backend
  statement {
    sid     = "DenyBootstrapIdentityChanges"
    effect  = "Deny"
    actions = ["iam:*"]
    resources = [
      aws_iam_openid_connect_provider.github.arn,
      local.protected_role_pattern,
      "arn:${local.partition}:iam::${local.account_id}:policy/${local.name}-gha-*",
    ]
  }

  statement {
    sid    = "DenyStateBucketChanges"
    effect = "Deny"
    actions = [
      "s3:DeleteBucket",
      "s3:DeleteBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketAcl",
      "s3:PutBucketVersioning",
      "s3:PutLifecycleConfiguration",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteObjectVersion",
    ]
    resources = [local.tfstate_bucket_arn, "${local.tfstate_bucket_arn}/*"]
  }

  statement {
    sid       = "DenyAccountLevelChanges"
    effect    = "Deny"
    actions   = ["organizations:Leave*", "organizations:Delete*", "account:*", "iam:CreateUser", "iam:CreateAccessKey", "iam:CreateLoginProfile"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "apply" {
  name        = "${local.apply_role_name}-policy"
  description = "Permissions for the core-infra GitHub Actions apply/destroy pipeline"
  policy      = data.aws_iam_policy_document.apply.json

  tags = merge(local.common_tags, {
    Name = "${local.apply_role_name}-policy"
  })
}

resource "aws_iam_role_policy_attachment" "apply" {
  role       = aws_iam_role.apply.name
  policy_arn = aws_iam_policy.apply.arn
}
