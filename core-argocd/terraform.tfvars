aws_region        = "eu-west-2"
environment_name  = "dev"
business_division = "devops"

argocd_subdomain    = "argocd"
git_repository_url  = "https://github.com/nadeembhatti1970/stfpgo.git"
git_target_revision = "main"
gitops_path         = "core-sftpgo/argocd/apps"

tags = {
  Terraform   = "true"
  Environment = "dev"
  Project     = "argocd"
  ManagedBy   = "platform-team"
}
