# Core Infrastructure

Terraform infrastructure for the development platform in AWS `eu-west-2`.
Each top-level project is an independent Terraform root module. Most use
separate S3 state keys; the S3 backend bootstrap project keeps its own state
locally. GitHub Actions validates changes, plans changes on non-main branches,
and applies changes from `main`.

## Projects

| Project | Purpose | Depends on |
| --- | --- | --- |
| [s3-remote-backend](./s3-remote-backend/README.md) | Creates the encrypted, versioned S3 bucket used for remote Terraform state. Bootstrap project; it keeps local Terraform state. | AWS credentials with permission to create the bucket |
| [github-oidc](./github-oidc/README.md) | Configures GitHub Actions OIDC and AWS plan/apply roles. Bootstrap project; CI runs static checks only. | State bucket; AWS credentials with permission to manage IAM |
| [core-vpc](./core-vpc/README.md) | VPC, public/private subnets, Internet Gateway, and a shared NAT Gateway. | State bucket |
| [core-route53](./core-route53/README.md) | Public Route 53 hosted zone for the platform domain. | State bucket |
| [core-eks](./core-eks/README.md) | EKS control plane, private managed node group, access, and foundational add-ons/controllers. | `core-vpc`, `github-oidc` |
| [core-acm](./core-acm/README.md) | ACM certificate and DNS validation records. | `core-route53` |
| [core-eks-karpenter](./core-eks-karpenter/README.md) | Karpenter controller, permissions, interruption handling, and node provisioning manifests. | `core-vpc`, `core-eks` |
| [core-eks-telemetry](./core-eks-telemetry/README.md) | ADOT collection, Amazon Managed Service for Prometheus, and Amazon Managed Grafana. | `core-vpc`, `core-eks` |
| [core-argocd](./core-argocd/README.md) | Argo CD and the root GitOps application, exposed through an HTTPS load balancer. | `core-eks`, `core-route53`, `core-acm`; GitHub OIDC apply role needs ECR token access |

The VPC project contains the reusable [VPC module](./core-vpc/modules/vpc/README.md).

## Bootstrap and deployment

The two bootstrap projects are not applied by the normal reusable CI pipeline:

1. With AWS credentials that can provision the backend, apply
   [`s3-remote-backend`](./s3-remote-backend/README.md). Its Terraform state is
   local; keep that state file safe.
2. Confirm the bucket name matches the S3 backend configuration in the other
   projects (`tfstate-dev-eu-west-2-8cbztj` in this checkout). Then apply
   [`github-oidc`](./github-oidc/README.md) with AWS credentials authorized to
   create the OIDC provider and IAM roles.
3. Apply the platform projects in dependency order: `core-vpc` and
   `core-route53`; then `core-eks` and `core-acm`; then the EKS add-ons
   (`core-eks-karpenter`, `core-eks-telemetry`) and `core-argocd`. The project
   workflows and the `rebuild` workflow encode these dependencies.

For a project, run Terraform from that project's directory. For example:

```sh
cd core-vpc
terraform init
terraform plan
terraform apply
```

The bootstrap projects use the static CI mode and therefore require a manual
Terraform apply. The other project workflows run on relevant pushes and can
also be started with **Actions > Run workflow**. Non-main branches plan; `main`
applies. Review the plan and its destroy-gate result before merging changes.

## Validation and safety

The shared workflow runs Terraform formatting and validation, Checkov static
analysis, a plan and plan scan where AWS access is configured, the destroy
gate, and Terraform tests under each project's `testing/` directory. Projects
with Kubernetes manifests additionally validate and apply those manifests.

The development environment is intentionally torn down daily at 17:00 London
time. The teardown removes Kubernetes-managed AWS resources first, then
`core-eks-karpenter`, `core-eks-telemetry`, and `core-argocd`, followed by
`core-eks` and `core-vpc`. It keeps the state bucket, GitHub OIDC
configuration, Route 53 hosted zone, and ACM certificate. Run the `rebuild`
workflow on `main` to recreate the cluster environment.

Terraform state and plans can contain sensitive data. Do not commit state,
plan files, credentials, or secrets. `terraform.tfvars` is tracked for
non-secret configuration; pass sensitive values through an appropriate secret
store or `TF_VAR_...` environment variable instead. In particular, Argo CD
stores a temporary ECR authorization token in Terraform state, and Grafana
dashboard provisioning can require a sensitive API token.

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

## Repository layout

- `.github/workflows/` contains per-project workflows and shared apply,
  rebuild, and teardown workflows.
- `.github/scripts/` contains Kubernetes manifest handling, upstream workflow
  coordination, and destroy-gate support.
- `<project>/testing/` contains Terraform tests and the destroy allow-list.
- `AGENTS.md` and `SKILL.md` document infrastructure contribution and
  verification requirements.
