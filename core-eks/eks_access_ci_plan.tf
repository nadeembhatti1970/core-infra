# ------------------------------------------------------------------------------
# Read-only cluster access for the GitHub Actions plan role (pull requests)
# Needed for:
#   - terraform plan refresh of helm/kubernetes resources (helm reads release Secrets)
#   - kubectl apply --dry-run=client of the k8s-* manifests (GET of live objects)
# AmazonEKSAdminViewPolicy grants get/list/watch on all resources, including
# Secrets, and no write verbs.
# ------------------------------------------------------------------------------
resource "aws_eks_access_entry" "ci_plan" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.terraform_remote_state.github_oidc.outputs.plan_role_arn
  type          = "STANDARD"

  tags = merge(var.tags, {
    Name        = "${local.name}-ci-plan-access"
    Environment = var.environment_name
    Component   = "EKS Access"
  })
}

resource "aws_eks_access_policy_association" "ci_plan_view" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_eks_access_entry.ci_plan.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy"

  access_scope {
    type = "cluster"
  }
}
