# Resolve the IAM Identity Center role itself, not an STS session ARN. The
# access entry therefore applies to every session that assumes this role.
data "aws_iam_roles" "sso_administrator_access" {
  name_regex  = "^AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/${var.aws_region}/"
}

resource "aws_eks_access_entry" "sso_administrator_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = one(data.aws_iam_roles.sso_administrator_access.arns)
  type          = "STANDARD"

  tags = merge(var.tags, {
    Name        = "${local.name}-sso-administrator-access"
    Environment = var.environment_name
    Component   = "EKS Access"
  })
}

resource "aws_eks_access_policy_association" "sso_administrator_access" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.sso_administrator_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
