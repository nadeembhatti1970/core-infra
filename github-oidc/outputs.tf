##############################################
# Outputs (consumed by core-eks via remote state and by the
# GitHub repository variables AWS_PLAN_ROLE_ARN / AWS_APPLY_ROLE_ARN)
##############################################
output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "plan_role_arn" {
  description = "Role assumed by pull_request workflows (set as repo variable AWS_PLAN_ROLE_ARN)"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Role assumed by workflows on the apply branch (set as repo variable AWS_APPLY_ROLE_ARN)"
  value       = aws_iam_role.apply.arn
}
