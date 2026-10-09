# --------------------------------------------------------------------
# Unit tests: plan-only against mocked AWS/Helm/Kubernetes/HTTP providers
# (no credentials or network needed). The core-vpc remote state is
# overridden with fixed VPC/subnet IDs and AWS lookups return fixed data.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:user/terraform"
      user_id    = "AIDAEXAMPLEUSERID"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"pods.eks.amazonaws.com\"},\"Action\":[\"sts:AssumeRole\",\"sts:TagSession\"]}]}"
    }
  }

  mock_data "aws_eks_addon_version" {
    defaults = {
      version = "v1.0.0-eksbuild.1"
    }
  }

  mock_data "aws_eks_cluster_auth" {
    defaults = {
      token = "k8s-aws-v1.mocktoken"
    }
  }
}

mock_provider "helm" {}

mock_provider "kubernetes" {}

mock_provider "http" {
  mock_data "http" {
    defaults = {
      status_code   = 200
      response_body = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"elasticloadbalancing:Describe*\"],\"Resource\":\"*\"}]}"
    }
  }
}

override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id             = "vpc-0123456789abcdef0"
      private_subnet_ids = ["subnet-0aaaaaaaaaaaaaaa1", "subnet-0aaaaaaaaaaaaaaa2", "subnet-0aaaaaaaaaaaaaaa3"]
      public_subnet_ids  = ["subnet-0bbbbbbbbbbbbbbb1", "subnet-0bbbbbbbbbbbbbbb2", "subnet-0bbbbbbbbbbbbbbb3"]
    }
  }
}

variables {
  aws_region                           = "eu-west-2"
  environment_name                     = "dev"
  business_division                    = "devops"
  cluster_name                         = "dev-eks-cluster"
  cluster_version                      = "1.36"
  cluster_service_ipv4_cidr            = "172.20.0.0/16"
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]
  node_instance_types                  = ["t3.medium"]
  node_capacity_type                   = "ON_DEMAND"
  node_disk_size                       = 20
}

run "cluster_name_follows_naming_convention" {
  command = plan

  assert {
    condition     = aws_eks_cluster.main.name == "devops-dev-dev-eks-cluster"
    error_message = "Cluster name must be <business_division>-<environment_name>-<cluster_name>"
  }

  assert {
    condition     = aws_iam_role.eks_cluster.name == "devops-dev-eks-cluster-role" && aws_iam_role.eks_nodegroup_role.name == "devops-dev-eks-nodegroup-role"
    error_message = "Cluster and node group IAM roles must be prefixed with <business_division>-<environment_name>"
  }

  assert {
    condition     = output.to_configure_kubectl == "aws eks --region eu-west-2 update-kubeconfig --name devops-dev-dev-eks-cluster"
    error_message = "to_configure_kubectl output must reference the region and the full cluster name"
  }
}

run "cluster_settings_follow_variables" {
  command = plan

  assert {
    condition     = aws_eks_cluster.main.version == "1.36"
    error_message = "Cluster Kubernetes version must equal var.cluster_version"
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_public_access == true && aws_eks_cluster.main.vpc_config[0].endpoint_private_access == false
    error_message = "Endpoint access flags must follow var.cluster_endpoint_public_access / var.cluster_endpoint_private_access"
  }

  assert {
    condition     = toset(aws_eks_cluster.main.vpc_config[0].subnet_ids) == toset(["subnet-0aaaaaaaaaaaaaaa1", "subnet-0aaaaaaaaaaaaaaa2", "subnet-0aaaaaaaaaaaaaaa3"])
    error_message = "Control plane ENIs must be placed in the remote-state private subnets"
  }

  assert {
    condition     = aws_eks_cluster.main.kubernetes_network_config[0].service_ipv4_cidr == "172.20.0.0/16"
    error_message = "Service CIDR must equal var.cluster_service_ipv4_cidr"
  }

  assert {
    condition     = length(aws_eks_cluster.main.enabled_cluster_log_types) == 5
    error_message = "All five control plane log types must be enabled"
  }

  assert {
    condition     = aws_eks_cluster.main.access_config[0].authentication_mode == "API_AND_CONFIG_MAP"
    error_message = "Cluster must use API_AND_CONFIG_MAP authentication mode"
  }
}

run "private_endpoint_restricted_cidrs_edge_case" {
  command = plan

  variables {
    cluster_endpoint_private_access      = true
    cluster_endpoint_public_access_cidrs = ["203.0.113.10/32"]
  }

  assert {
    condition     = aws_eks_cluster.main.vpc_config[0].endpoint_private_access == true
    error_message = "Private endpoint must be enabled when var.cluster_endpoint_private_access is true"
  }

  assert {
    condition     = toset(aws_eks_cluster.main.vpc_config[0].public_access_cidrs) == toset(["203.0.113.10/32"])
    error_message = "Public endpoint CIDRs must equal var.cluster_endpoint_public_access_cidrs"
  }
}

run "secrets_encryption_uses_rotating_kms_key" {
  command = plan

  assert {
    condition     = aws_eks_cluster.main.encryption_config[0].resources == toset(["secrets"])
    error_message = "Cluster must envelope-encrypt Kubernetes secrets (CKV_AWS_58)"
  }

  assert {
    condition     = aws_kms_key.eks_secrets.enable_key_rotation == true
    error_message = "Secrets KMS key must have automatic rotation enabled"
  }

  assert {
    condition     = aws_kms_key.eks_secrets.deletion_window_in_days >= 7 && aws_kms_key.eks_secrets.deletion_window_in_days <= 30
    error_message = "Secrets KMS key deletion window must be between 7 and 30 days"
  }

  assert {
    condition     = jsondecode(aws_kms_key.eks_secrets.policy).Statement[0].Principal.AWS == "arn:aws:iam::111122223333:root"
    error_message = "KMS key policy must grant the account root (IAM delegation)"
  }

  assert {
    condition     = aws_kms_alias.eks_secrets.name == "alias/devops-dev-dev-eks-cluster-secrets"
    error_message = "KMS alias must follow alias/<cluster name>-secrets"
  }
}

run "node_group_settings_follow_variables" {
  command = plan

  variables {
    node_instance_types = ["m5.large"]
    node_capacity_type  = "SPOT"
    node_disk_size      = 50
  }

  assert {
    condition     = aws_eks_node_group.private_nodes.node_group_name == "devops-dev-private-ng"
    error_message = "Node group name must be <business_division>-<environment_name>-private-ng"
  }

  assert {
    condition     = aws_eks_node_group.private_nodes.instance_types == tolist(["m5.large"]) && aws_eks_node_group.private_nodes.capacity_type == "SPOT" && aws_eks_node_group.private_nodes.disk_size == 50
    error_message = "Node group instance types, capacity type and disk size must follow variables"
  }

  assert {
    condition     = aws_eks_node_group.private_nodes.ami_type == "AL2023_x86_64_STANDARD"
    error_message = "Node group must use the Amazon Linux 2023 EKS AMI"
  }

  assert {
    condition     = aws_eks_node_group.private_nodes.scaling_config[0].min_size == 2 && aws_eks_node_group.private_nodes.scaling_config[0].desired_size == 2 && aws_eks_node_group.private_nodes.scaling_config[0].max_size == 6
    error_message = "Node group scaling must be min 2 / desired 2 / max 6"
  }

  assert {
    condition     = aws_eks_node_group.private_nodes.labels["env"] == "dev" && aws_eks_node_group.private_nodes.labels["team"] == "devops"
    error_message = "Node labels must carry environment and business division"
  }
}

run "iam_policy_attachments_are_correct" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.eks_cluster_policy.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" && aws_iam_role_policy_attachment.eks_vpc_resource_controller.policy_arn == "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
    error_message = "Cluster role must have AmazonEKSClusterPolicy and AmazonEKSVPCResourceController"
  }

  assert {
    condition = toset([
      aws_iam_role_policy_attachment.eks_worker_node_policy.policy_arn,
      aws_iam_role_policy_attachment.eks_cni_policy.policy_arn,
      aws_iam_role_policy_attachment.eks_ecr_policy.policy_arn,
      ]) == toset([
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    ])
    error_message = "Node role must have worker node, CNI and ECR read-only managed policies"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ebs_csi_managed_policy_attach.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    error_message = "EBS CSI role must have AmazonEBSCSIDriverPolicy attached"
  }

  assert {
    condition     = aws_iam_policy.lbc_iam_policy.name == "devops-dev-AWSLoadBalancerControllerIAMPolicy"
    error_message = "LBC IAM policy name must be prefixed with <business_division>-<environment_name>"
  }
}

run "pod_identity_associations_target_correct_service_accounts" {
  command = plan

  assert {
    condition     = aws_eks_pod_identity_association.ebs_csi.namespace == "kube-system" && aws_eks_pod_identity_association.ebs_csi.service_account == "ebs-csi-controller-sa"
    error_message = "EBS CSI pod identity must bind kube-system/ebs-csi-controller-sa"
  }

  assert {
    condition     = aws_eks_pod_identity_association.lbc.namespace == "kube-system" && aws_eks_pod_identity_association.lbc.service_account == "aws-load-balancer-controller"
    error_message = "LBC pod identity must bind kube-system/aws-load-balancer-controller"
  }

  assert {
    condition     = aws_eks_pod_identity_association.externaldns.namespace == "external-dns" && aws_eks_pod_identity_association.externaldns.service_account == "external-dns"
    error_message = "ExternalDNS pod identity must bind external-dns/external-dns"
  }

  assert {
    condition     = contains(jsondecode(data.aws_iam_policy_document.assume_role.json).Statement[0].Action, "sts:TagSession")
    error_message = "Pod identity trust policy must allow sts:TagSession"
  }
}

run "addons_and_helm_releases_configured" {
  command = plan

  assert {
    condition     = aws_eks_addon.podidentity.addon_name == "eks-pod-identity-agent" && aws_eks_addon.ebs_csi.addon_name == "aws-ebs-csi-driver" && aws_eks_addon.externaldns.addon_name == "external-dns"
    error_message = "Pod identity agent, EBS CSI and ExternalDNS addons must be installed"
  }

  assert {
    condition     = aws_eks_addon.ebs_csi.resolve_conflicts_on_update == "OVERWRITE"
    error_message = "Addons must resolve conflicts with OVERWRITE"
  }

  assert {
    condition     = one([for s in helm_release.loadbalancer_controller.set : s.value if s.name == "vpcId"]) == "vpc-0123456789abcdef0"
    error_message = "LBC Helm release must receive the remote-state VPC ID"
  }

  assert {
    condition     = helm_release.secrets_store_csi_driver.namespace == "kube-system" && helm_release.aws_secrets_provider.namespace == "kube-system"
    error_message = "Secrets Store CSI driver and ASCP must be installed in kube-system"
  }
}

run "subnet_tags_applied_for_load_balancers" {
  command = plan

  assert {
    condition     = length(aws_ec2_tag.eks_subnet_tag_public_elb) == 3 && length(aws_ec2_tag.eks_subnet_tag_private_elb) == 3
    error_message = "One ELB role tag per public and private subnet is expected"
  }

  assert {
    condition     = alltrue([for t in aws_ec2_tag.eks_subnet_tag_private_cluster : t.key == "kubernetes.io/cluster/devops-dev-dev-eks-cluster" && t.value == "shared"])
    error_message = "Private subnets must carry the shared cluster discovery tag"
  }
}
