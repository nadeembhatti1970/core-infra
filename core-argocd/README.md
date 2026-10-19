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

## Local checks and GitHub Actions

Run checks from a Terraform project directory. Install Terraform 1.16.5 and
Checkov using the repository requirements to match CI:
`python3 -m pip install -r ../requirements.txt`. The AWS region used by these
projects is `eu-west-2`.

```sh
terraform init -test-directory=testing
terraform fmt -check -recursive -diff
terraform validate
checkov -d . --framework terraform --compact --quiet
terraform test -test-directory=testing
```

For projects with a remote S3 backend, configure AWS credentials that can read
the backend and any required upstream state before initializing. For
`github-oidc`, initialize without a backend:
`terraform init -backend=false -test-directory=testing`. The
`s3-remote-backend` project uses local state, so the regular init command above
applies.

To run the plan scan and deletion safeguard used by CI, configure plan-role
access and ensure prerequisite projects have state available:

```sh
terraform plan -lock-timeout=10m -out=tfplan.binary -no-color
terraform show -json tfplan.binary > tfplan.json
skips=$(../.github/scripts/checkov_skips.sh . || true)
if [ -n "$skips" ]; then
  checkov -f tfplan.json --skip-check "$skips" --compact --quiet
else
  checkov -f tfplan.json --compact --quiet
fi
python3 ../.github/scripts/destroy_gate.py tfplan.json testing/.checkov-allowlist.json
```

Run these from the project directory, one level below the repository root.
Review the plan and destroy-gate result before applying. Do not commit plan or
state files.

Project workflows run on relevant pushes and can be started from **Actions**
with **Run workflow**. Non-`main` runs perform formatting, validation, static
Checkov, plan, plan Checkov, the destroy gate, and Terraform tests. A `main` run
performs the same checks and applies the plan. EKS add-on workflows also
validate their Kubernetes manifests and dry-run or apply them. Open the
workflow's Terraform job to see Checkov results and the plan summary.

The `s3-remote-backend` and `github-oidc` workflows run static checks and tests
only; they do not assume AWS credentials or plan/apply. Review a local plan and
apply those bootstrap projects manually.


## Outputs

| Name | Description |
| --- | --- |
| `argocd_url` | HTTPS URL for the Argo CD UI |
| `argocd_namespace` | Kubernetes namespace containing Argo CD |
| `argocd_chart_version` | Installed Helm chart version |
| `app_of_apps_repository` | Git repository tracked by the root Application |
| `app_of_apps_path` | Path containing child Application manifests |
