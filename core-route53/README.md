# core-route53

Creates the public Route 53 hosted zone for the platform domain (default:
`bizopensource.com`). After creating the zone, configure the registered
domain's name servers at IONOS using the `name_servers` output. DNS records
from dependent projects, including ACM validation and application ingress,
are then created in this zone.

The remote state key is `route53/dev/terraform.tfstate`. Apply from this
directory with `terraform init`, `terraform plan`, and `terraform apply`, or
use the `core-route53` GitHub Actions workflow. The scheduled teardown
deliberately keeps this hosted zone: replacing it would change its name
servers at the registrar. Tests are in `testing/`.

The generated reference below lists this project's requirements, resources,
inputs, and outputs.

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.68.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_route53_zone.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_business_division"></a> [business\_division](#input\_business\_division) | Business Division in the large organization this infrastructure belongs to | `string` | `"devops"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the public Route53 hosted zone (registered at IONOS) | `string` | `"bizopensource.com"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in resource names and tags | `string` | `"dev"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to Route53 resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_name_servers"></a> [name\_servers](#output\_name\_servers) | Name servers to configure at IONOS for the domain |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | Route53 hosted zone ID |
| <a name="output_zone_name"></a> [zone\_name](#output\_zone\_name) | Route53 hosted zone domain name |
<!-- END_TF_DOCS -->