# s3-remote-backend

Creates the S3 bucket used by the other projects for Terraform state. The
bucket is versioned, encrypted, blocked from public access, and configured
with a lifecycle rule. Its name includes a generated suffix and is exposed by
the `tfstate_bucket_id` and `tfstate_bucket_arn` outputs.

This is the first bootstrap step. It intentionally has no S3 backend
configured, so Terraform stores its own state locally. Protect that state
file, and confirm the resulting bucket name matches the bucket configured in
each remote-backend project before initializing them. The standard workflows
run static validation and tests only; apply this project manually using AWS
credentials with permission to create the bucket.

Run `terraform init`, `terraform plan`, and `terraform apply` from this
directory. Tests and the destroy allow-list are in `testing/`.

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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.67.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.tfstate_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.tfstate_lifecycle](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.tfstate_block_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.tfstate_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.tfstate_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy backend (e.g., us-west-2) | `string` | `"eu-west-2"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Deployment environment (e.g., dev, staging, prod) | `string` | `"dev"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_tfstate_bucket_arn"></a> [tfstate\_bucket\_arn](#output\_tfstate\_bucket\_arn) | ARN of the Terraform remote state S3 bucket |
| <a name="output_tfstate_bucket_id"></a> [tfstate\_bucket\_id](#output\_tfstate\_bucket\_id) | Bucket ID (same as name) for Terraform state |
<!-- END_TF_DOCS -->