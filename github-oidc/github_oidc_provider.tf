##############################################
# GitHub Actions OIDC Identity Provider
# AWS validates GitHub's certificate chain itself, so no thumbprint is required.
##############################################
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${local.github_oidc_host}"
  client_id_list = ["sts.amazonaws.com"]

  tags = merge(local.common_tags, {
    Name = "${local.name}-github-actions-oidc"
  })
}
