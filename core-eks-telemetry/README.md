<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.20 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.28 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.67.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 3.3.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_eks_addon.adot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.cert_manager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_state_metrics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.prometheus_node_exporter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_pod_identity_association.adot_collector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_grafana_workspace.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/grafana_workspace) | resource |
| [aws_iam_policy.adot_collector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.amg_prometheus_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.amg_sns_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.adot_collector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.amg_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.adot_collector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amg_prometheus_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amg_sns_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.amg_xray_readonly_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_prometheus_workspace.amp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_workspace) | resource |
| [kubernetes_cluster_role_binding_v1.otel_collector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding_v1) | resource |
| [kubernetes_cluster_role_v1.otel_collector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_v1) | resource |
| [kubernetes_service_account_v1.adot_collector](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account_v1) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_addon_version.adot_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.adot_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.cert_manager_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.cert_manager_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.kube_state_metrics_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.kube_state_metrics_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.prometheus_node_exporter_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.prometheus_node_exporter_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.xray_readonly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.adot_collector_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [terraform_remote_state.eks](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_business_division"></a> [business\_division](#input\_business\_division) | Business Division in the large organization this infrastructure belongs to | `string` | `"devops"` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in resource names and tags | `string` | `"dev"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to EKS and related resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_adot_addon_id"></a> [adot\_addon\_id](#output\_adot\_addon\_id) | ADOT EKS Addon ID |
| <a name="output_adot_addon_version"></a> [adot\_addon\_version](#output\_adot\_addon\_version) | ADOT EKS Addon Version |
| <a name="output_adot_collector_role_arn"></a> [adot\_collector\_role\_arn](#output\_adot\_collector\_role\_arn) | IAM Role ARN for ADOT Collector |
| <a name="output_amg_iam_role_arn"></a> [amg\_iam\_role\_arn](#output\_amg\_iam\_role\_arn) | ARN of the AMG IAM role |
| <a name="output_amg_iam_role_name"></a> [amg\_iam\_role\_name](#output\_amg\_iam\_role\_name) | Name of the AMG service role |
| <a name="output_amg_workspace_arn"></a> [amg\_workspace\_arn](#output\_amg\_workspace\_arn) | ARN of the Grafana workspace |
| <a name="output_amg_workspace_endpoint"></a> [amg\_workspace\_endpoint](#output\_amg\_workspace\_endpoint) | Endpoint URL for the Grafana workspace |
| <a name="output_amg_workspace_id"></a> [amg\_workspace\_id](#output\_amg\_workspace\_id) | ID of the Grafana workspace |
| <a name="output_amg_workspace_url"></a> [amg\_workspace\_url](#output\_amg\_workspace\_url) | Full URL to access Grafana workspace |
| <a name="output_amp_endpoint"></a> [amp\_endpoint](#output\_amp\_endpoint) | AMP Remote Write Endpoint |
| <a name="output_amp_query_endpoint"></a> [amp\_query\_endpoint](#output\_amp\_query\_endpoint) | AMP Query Endpoint |
| <a name="output_amp_workspace_id"></a> [amp\_workspace\_id](#output\_amp\_workspace\_id) | AMP Workspace ID |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | n/a |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | -------------------------------------------------------------------- Output the EKS eks\_cluster\_name and eks\_cluster\_id from the remote EKS state -------------------------------------------------------------------- |
| <a name="output_kube_state_metrics_addon_id"></a> [kube\_state\_metrics\_addon\_id](#output\_kube\_state\_metrics\_addon\_id) | Kube State Metrics EKS Addon ID |
| <a name="output_kube_state_metrics_version"></a> [kube\_state\_metrics\_version](#output\_kube\_state\_metrics\_version) | Kube State Metrics EKS Addon Version |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | -------------------------------------------------------------------- Output the list of private subnets from the VPC -------------------------------------------------------------------- |
| <a name="output_prometheus_node_exporter_addon_id"></a> [prometheus\_node\_exporter\_addon\_id](#output\_prometheus\_node\_exporter\_addon\_id) | Prometheus Node Exporter EKS Addon ID |
| <a name="output_prometheus_node_exporter_addon_version"></a> [prometheus\_node\_exporter\_addon\_version](#output\_prometheus\_node\_exporter\_addon\_version) | Prometheus Node Exporter EKS Addon Version |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | -------------------------------------------------------------------- Output the list of public subnets from the VPC -------------------------------------------------------------------- |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | -------------------------------------------------------------------- Output the VPC ID from the remote VPC state -------------------------------------------------------------------- |
<!-- END_TF_DOCS -->