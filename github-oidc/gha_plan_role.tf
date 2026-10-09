##############################################
# Plan Role: assumed by pull_request workflows
# Read-only AWS access plus Terraform state locking; used for
# fmt/validate/checkov/plan/test but never apply.
##############################################
data "aws_iam_policy_document" "plan_trust" {
  statement {
    sid     = "GitHubActionsPullRequests"
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

    # Only pull_request events from this repository
    condition {
      test     = "StringEquals"
      variable = "${local.github_oidc_host}:sub"
      values   = ["repo:${var.github_repository}:pull_request"]
    }
  }
}

resource "aws_iam_role" "plan" {
  name                 = local.plan_role_name
  description          = "GitHub Actions (pull_request) - Terraform plan for ${var.github_repository}"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust.json
  max_session_duration = var.max_session_duration

  tags = merge(local.common_tags, {
    Name = local.plan_role_name
  })
}

# Read-only access to refresh every resource during plan
resource "aws_iam_role_policy_attachment" "plan_readonly" {
  role       = aws_iam_role.plan.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

# State access: read state, write only S3 lock files, decrypt SSE-KMS (aws/s3) objects
data "aws_iam_policy_document" "plan_state" {
  statement {
    sid       = "ListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.tfstate_bucket_arn]
  }

  statement {
    sid       = "ReadState"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${local.tfstate_bucket_arn}/*"]
  }

  statement {
    sid       = "ManageStateLockFiles"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${local.tfstate_bucket_arn}/*.tflock"]
  }

  statement {
    sid       = "DecryptStateViaS3"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = ["arn:${local.partition}:kms:${var.aws_region}:${local.account_id}:key/*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "plan_state" {
  name   = "${local.plan_role_name}-state"
  role   = aws_iam_role.plan.id
  policy = data.aws_iam_policy_document.plan_state.json
}
