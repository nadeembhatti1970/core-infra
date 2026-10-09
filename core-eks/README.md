<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.67.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 3.3.0 |
| <a name="provider_http"></a> [http](#provider\_http) | 3.6.2 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ec2_tag.eks_subnet_tag_private_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.eks_subnet_tag_private_elb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.eks_subnet_tag_public_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_ec2_tag.eks_subnet_tag_public_elb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_tag) | resource |
| [aws_eks_addon.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.externaldns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.podidentity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.private_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_eks_pod_identity_association.ebs_csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_eks_pod_identity_association.externaldns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_eks_pod_identity_association.lbc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_pod_identity_association) | resource |
| [aws_iam_policy.lbc_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ebs_csi_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.eks_nodegroup_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.externaldns_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.lbc_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.eks_cluster_secrets_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_managed_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_cni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_ecr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_vpc_resource_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.eks_worker_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.externaldns_managed_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lbc_iam_role_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.eks_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.eks_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [helm_release.aws_secrets_provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.loadbalancer_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.secrets_store_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_addon_version.ebs_csi_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.ebs_csi_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.externaldns_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.pia_default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_addon_version.pia_latest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [http_http.lbc_iam_policy](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [terraform_remote_state.vpc](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | `"eu-west-2"` | no |
| <a name="input_business_division"></a> [business\_division](#input\_business\_division) | Business Division in the large organization this infrastructure belongs to | `string` | `"devops"` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Whether to enable private access to EKS control plane endpoint | `bool` | `false` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether to enable public access to EKS control plane endpoint | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks allowed to access public EKS endpoint | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster. Also used as a prefix in names of related resources. | `string` | `"dev-eks-cluster"` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | Service CIDR range for Kubernetes services. Optional — leave null to use AWS default. | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes minor version to use for the EKS cluster (e.g. 1.28, 1.29) | `string` | `null` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Environment name used in resource names and tags | `string` | `"dev"` | no |
| <a name="input_node_capacity_type"></a> [node\_capacity\_type](#input\_node\_capacity\_type) | Instance capacity type: ON\_DEMAND or SPOT | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_disk_size"></a> [node\_disk\_size](#input\_node\_disk\_size) | Disk size in GiB for worker nodes | `number` | `20` | no |
| <a name="input_node_instance_types"></a> [node\_instance\_types](#input\_node\_instance\_types) | List of EC2 instance types for the node group | `list(string)` | <pre>[<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to EKS and related resources | `map(string)` | <pre>{<br/>  "Terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ebs_csi_addon_arn"></a> [ebs\_csi\_addon\_arn](#output\_ebs\_csi\_addon\_arn) | ARN of the installed EBS CSI addon |
| <a name="output_ebs_csi_addon_default_version"></a> [ebs\_csi\_addon\_default\_version](#output\_ebs\_csi\_addon\_default\_version) | Default EBS CSI addon version compatible with the EKS cluster version |
| <a name="output_ebs_csi_addon_id"></a> [ebs\_csi\_addon\_id](#output\_ebs\_csi\_addon\_id) | ID of the installed EBS CSI addon |
| <a name="output_ebs_csi_addon_latest_version"></a> [ebs\_csi\_addon\_latest\_version](#output\_ebs\_csi\_addon\_latest\_version) | Latest available EBS CSI addon version for the current EKS cluster |
| <a name="output_ebs_csi_iam_role_arn"></a> [ebs\_csi\_iam\_role\_arn](#output\_ebs\_csi\_iam\_role\_arn) | IAM Role ARN for Amazon EBS CSI Driver |
| <a name="output_ebs_csi_pod_identity_association_arn"></a> [ebs\_csi\_pod\_identity\_association\_arn](#output\_ebs\_csi\_pod\_identity\_association\_arn) | EBS CSI Driver Pod Identity Association ARN |
| <a name="output_eks_cluster_certificate_authority_data"></a> [eks\_cluster\_certificate\_authority\_data](#output\_eks\_cluster\_certificate\_authority\_data) | Base64 encoded CA certificate for kubectl config |
| <a name="output_eks_cluster_endpoint"></a> [eks\_cluster\_endpoint](#output\_eks\_cluster\_endpoint) | EKS API server endpoint |
| <a name="output_eks_cluster_id"></a> [eks\_cluster\_id](#output\_eks\_cluster\_id) | The name/id of the EKS cluster. |
| <a name="output_eks_cluster_name"></a> [eks\_cluster\_name](#output\_eks\_cluster\_name) | EKS cluster name |
| <a name="output_eks_cluster_version"></a> [eks\_cluster\_version](#output\_eks\_cluster\_version) | EKS Kubernetes version |
| <a name="output_eks_node_instance_role_arn"></a> [eks\_node\_instance\_role\_arn](#output\_eks\_node\_instance\_role\_arn) | IAM Role ARN used by EKS node group (EC2 worker nodes) |
| <a name="output_eks_secrets_kms_key_arn"></a> [eks\_secrets\_kms\_key\_arn](#output\_eks\_secrets\_kms\_key\_arn) | ARN of the KMS key used for EKS secrets envelope encryption |
| <a name="output_externaldns_addon_arn"></a> [externaldns\_addon\_arn](#output\_externaldns\_addon\_arn) | n/a |
| <a name="output_externaldns_addon_id"></a> [externaldns\_addon\_id](#output\_externaldns\_addon\_id) | n/a |
| <a name="output_externaldns_addon_version"></a> [externaldns\_addon\_version](#output\_externaldns\_addon\_version) | ############################################# Outputs ############################################# |
| <a name="output_externaldns_pod_identity_association_id"></a> [externaldns\_pod\_identity\_association\_id](#output\_externaldns\_pod\_identity\_association\_id) | ############################################# Output ############################################# |
| <a name="output_externaldns_role_arn"></a> [externaldns\_role\_arn](#output\_externaldns\_role\_arn) | ############################################# Output ############################################# |
| <a name="output_helm_aws_secrets_provider_metadata"></a> [helm\_aws\_secrets\_provider\_metadata](#output\_helm\_aws\_secrets\_provider\_metadata) | Metadata for the AWS Secrets and Configuration Provider Helm release |
| <a name="output_helm_lbc_metadata"></a> [helm\_lbc\_metadata](#output\_helm\_lbc\_metadata) | Metadata Block outlining status of the deployed release. |
| <a name="output_helm_secrets_store_csi_driver_metadata"></a> [helm\_secrets\_store\_csi\_driver\_metadata](#output\_helm\_secrets\_store\_csi\_driver\_metadata) | Metadata for the Secrets Store CSI Driver Helm release |
| <a name="output_lbc_iam_policy_arn"></a> [lbc\_iam\_policy\_arn](#output\_lbc\_iam\_policy\_arn) | n/a |
| <a name="output_lbc_iam_role_arn"></a> [lbc\_iam\_role\_arn](#output\_lbc\_iam\_role\_arn) | AWS Load Balancer Controller IAM Role ARN |
| <a name="output_lbc_pod_identity_association_arn"></a> [lbc\_pod\_identity\_association\_arn](#output\_lbc\_pod\_identity\_association\_arn) | AWS Load Balancer Controller Pod Identity Association ARN |
| <a name="output_pod_identity_agent_eksaddon_arn"></a> [pod\_identity\_agent\_eksaddon\_arn](#output\_pod\_identity\_agent\_eksaddon\_arn) | n/a |
| <a name="output_pod_identity_agent_eksaddon_default_version"></a> [pod\_identity\_agent\_eksaddon\_default\_version](#output\_pod\_identity\_agent\_eksaddon\_default\_version) | Outputs |
| <a name="output_pod_identity_agent_eksaddon_id"></a> [pod\_identity\_agent\_eksaddon\_id](#output\_pod\_identity\_agent\_eksaddon\_id) | n/a |
| <a name="output_pod_identity_agent_eksaddon_lastest_version"></a> [pod\_identity\_agent\_eksaddon\_lastest\_version](#output\_pod\_identity\_agent\_eksaddon\_lastest\_version) | n/a |
| <a name="output_private_node_group_name"></a> [private\_node\_group\_name](#output\_private\_node\_group\_name) | Name of the EKS private node group |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | -------------------------------------------------------------------- Output the list of private subnets from the VPC -------------------------------------------------------------------- |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | -------------------------------------------------------------------- Output the list of public subnets from the VPC -------------------------------------------------------------------- |
| <a name="output_to_configure_kubectl"></a> [to\_configure\_kubectl](#output\_to\_configure\_kubectl) | Command to update local kubeconfig to connect to the EKS cluster |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | -------------------------------------------------------------------- Output the VPC ID from the remote VPC state -------------------------------------------------------------------- |
<!-- END_TF_DOCS -->