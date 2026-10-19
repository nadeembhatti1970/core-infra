# core-vpc

Builds the network foundation through the local
[`modules/vpc`](./modules/vpc/README.md) module: a VPC, public and private
subnets across the available Availability Zones, an Internet Gateway, and one
NAT Gateway shared by the private subnets. This single-NAT design reduces
development costs but makes outbound connectivity dependent on one gateway
and its Availability Zone.

Apply this project before `core-eks`. The remote state key is
`vpc/dev/terraform.tfstate`; dependent projects read the VPC and subnet outputs
from it. Run `terraform init`, `terraform plan`, and `terraform apply` from
this directory, or use the `core-vpc` GitHub Actions workflow. Tests are in
`testing/`.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./modules/vpc | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in resource names and tags | `string` | `"dev"` | no |
| <a name="input_subnet_newbits"></a> [subnet\_newbits](#input\_subnet\_newbits) | Number of new bits to add to VPC CIDR to generate subnets (e.g., 8 means /24 from /16) | `number` | `8` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Global tags to apply to all resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | Private subnets for EKS worker nodes |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | Public subnets for ALB, NLB, etc. |
| <a name="output_public_subnet_map"></a> [public\_subnet\_map](#output\_public\_subnet\_map) | Public subnets for ALB, NLB, etc. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPC ID used by EKS and other services |
<!-- END_TF_DOCS -->