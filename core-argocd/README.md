# Core Argo CD

Installs Argo CD into the EKS cluster managed by `core-eks` using the upstream
`argo-cd` Helm chart. An AWS Load Balancer Controller Ingress exposes the UI at
`argocd.<core-route53 zone>`; ExternalDNS publishes the hostname in that Route
53 zone, and the ALB terminates HTTPS with the ACM certificate from `core-acm`.

The Helm release bootstraps a root Argo CD `Application` (App of Apps). It
tracks the configured Git repository and recursively syncs child Application
manifests from `gitops_path`. The SFTPGo child application reads its Helm chart
from the private `sftpgo` ECR OCI repository. The SFTPGo publish workflow
updates that application's pinned chart version in Git after pushing a chart.
Argo CD receives an ECR authorization token through its Helm repository
credentials; the scheduled workflow refreshes it every six hours because ECR
authorization tokens expire after 12 hours. Terraform state therefore contains
the sensitive token and must remain protected by the encrypted S3 backend.

The S3 backend key is `argocd/dev/terraform.tfstate`. Override Git repository,
revision, path, hostname, or chart version with Terraform variables when needed.

## Apply

Initialize and apply from this directory after `core-eks`, `core-route53`, and
`core-acm` have been applied. The `github-oidc` apply role also needs the
`ecr:GetAuthorizationToken` permission from its updated policy before this
project can read the private chart repository:

```sh
terraform init
terraform plan
terraform apply
```

The current GitOps path is `core-sftpgo/argocd/apps`, containing an SFTPGo child
Application. The hostname is formed from `argocd_subdomain` and the zone name
read from the `core-route53` remote state. The ExternalDNS add-on in `core-eks`
publishes it, while the certificate ARN is read from the `core-acm` remote state.
The scheduled workflow refreshes the private ECR credential on the six-hour
schedule; a manual rebuild also refreshes it.

## Outputs

| Name | Description |
| --- | --- |
| `argocd_url` | HTTPS URL for the Argo CD UI |
| `argocd_namespace` | Kubernetes namespace containing Argo CD |
| `argocd_chart_version` | Installed Helm chart version |
| `app_of_apps_repository` | Git repository tracked by the root Application |
| `app_of_apps_path` | Path containing child Application manifests |
