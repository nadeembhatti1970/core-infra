# core-acm

Requests an ACM certificate for the domain managed by `core-route53`, creates
the DNS validation records, and waits for certificate validation. The default
subject alternative name is `*.bizopensource.com`; configure additional names
with `subject_alternative_names`.

Apply `core-route53` first. Once the certificate is validated, its
`certificate_arn` output can be used by load balancers, including the Argo CD
ingress. The Route 53 zone and certificate are retained by the scheduled
environment teardown.

The remote state key is `acm/dev/terraform.tfstate`. Run Terraform from this
directory (`terraform init`, `terraform plan`, then `terraform apply`), or use
the `core-acm` GitHub Actions workflow. CI plans changes on non-main branches
and applies on `main`; tests are in `testing/`.

The generated reference below lists this project's requirements, resources,
inputs, and outputs.

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
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_acm_certificate.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_route53_record.acm_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [terraform_remote_state.route53](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_business_division"></a> [business\_division](#input\_business\_division) | Business Division in the large organization this infrastructure belongs to | `string` | `"devops"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in resource names and tags | `string` | `"dev"` | no |
| <a name="input_subject_alternative_names"></a> [subject\_alternative\_names](#input\_subject\_alternative\_names) | Subject alternative names, relative to the zone apex (e.g. "*" => *.bizopensource.com) | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to ACM resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_certificate_arn"></a> [certificate\_arn](#output\_certificate\_arn) | ARN of the validated ACM certificate (use in alb.ingress.kubernetes.io/certificate-arn) |
| <a name="output_certificate_domains"></a> [certificate\_domains](#output\_certificate\_domains) | Domains covered by the certificate |
<!-- END_TF_DOCS -->