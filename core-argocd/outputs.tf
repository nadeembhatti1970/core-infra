output "argocd_url" {
  description = "HTTPS endpoint exposed through the Route 53 zone and ACM certificate"
  value       = "https://${local.argocd_domain}"
}

output "argocd_namespace" {
  description = "Kubernetes namespace containing Argo CD"
  value       = helm_release.argocd.namespace
}

output "argocd_chart_version" {
  description = "Installed Argo CD Helm chart version"
  value       = helm_release.argocd.version
}

output "app_of_apps_repository" {
  description = "Git repository configured for the App of Apps root application"
  value       = var.git_repository_url
}

output "app_of_apps_path" {
  description = "Repository path configured for child Argo CD Application manifests"
  value       = var.gitops_path
}
