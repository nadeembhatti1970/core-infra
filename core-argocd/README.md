# core-argocd

Installs Argo CD in the EKS cluster managed by `core-eks`. Its ingress is
published by ExternalDNS in the `core-route53` zone and uses the ACM
certificate from `core-acm`.

The root Argo CD Application follows the configured Git repository and syncs
child applications from `gitops_path` (currently `core-sftpgo/argocd/apps`).
The SFTPGo child application uses a chart in a private ECR OCI repository.
Terraform supplies Argo CD with an ECR authorization token; the workflow
refreshes that token every six hours because ECR tokens expire after 12 hours.
The token is stored in Terraform state, so access to the encrypted S3 state
backend must be restricted.

Apply `core-eks`, `core-route53`, and `core-acm` first. The GitHub OIDC apply
role must also have `ecr:GetAuthorizationToken` permission. The remote state
key is `argocd/dev/terraform.tfstate`. Configure repository, revision, GitOps
path, hostname, and chart version through the Terraform variables. Run
`terraform init`, `terraform plan`, and `terraform apply` here, or use the
GitHub Actions workflow. CI plans on non-main branches, applies on `main`, and
refreshes the ECR token on its six-hour schedule.

## Outputs

| Name | Description |
| --- | --- |
| `argocd_url` | HTTPS URL for the Argo CD UI |
| `argocd_namespace` | Kubernetes namespace containing Argo CD |
| `argocd_chart_version` | Installed Helm chart version |
| `app_of_apps_repository` | Git repository tracked by the root Application |
| `app_of_apps_path` | Path containing child Application manifests |
