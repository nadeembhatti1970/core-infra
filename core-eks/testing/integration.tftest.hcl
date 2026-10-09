# --------------------------------------------------------------------
# Integration tests: ephemeral apply against mocked AWS/Helm/Kubernetes/HTTP
# providers. Exercises computed attributes and outputs without touching AWS.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_resource "aws_eks_cluster" {
    defaults = {
      arn      = "arn:aws:eks:eu-west-2:111122223333:cluster/devops-dev-dev-eks-cluster"
      endpoint = "https://0123456789ABCDEF0123456789ABCDEF.gr7.eu-west-2.eks.amazonaws.com"
      certificate_authority = [
        {
          data = "bW9jay1jYS1jZXJ0aWZpY2F0ZQ=="
        },
      ]
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:eu-west-2:111122223333:key/11111111-2222-3333-4444-555555555555"
      key_id = "11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/mock-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/mock-policy"
    }
  }

  mock_resource "aws_eks_pod_identity_association" {
    defaults = {
      association_arn = "arn:aws:eks:eu-west-2:111122223333:podidentityassociation/devops-dev-dev-eks-cluster/a-0123456789abcdef0"
    }
  }

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

run "apply_outputs_cluster_details" {
  command = apply

  assert {
    condition     = output.eks_cluster_name == "devops-dev-dev-eks-cluster"
    error_message = "eks_cluster_name output must be the full <business_division>-<environment_name>-<cluster_name>"
  }

  assert {
    condition     = output.eks_cluster_endpoint == "https://0123456789ABCDEF0123456789ABCDEF.gr7.eu-west-2.eks.amazonaws.com"
    error_message = "eks_cluster_endpoint output must come from the cluster resource"
  }

  assert {
    condition     = output.eks_cluster_certificate_authority_data == "bW9jay1jYS1jZXJ0aWZpY2F0ZQ=="
    error_message = "eks_cluster_certificate_authority_data output must come from certificate_authority[0].data"
  }

  assert {
    condition     = output.eks_cluster_version == "1.36" && output.private_node_group_name == "devops-dev-private-ng"
    error_message = "Cluster version and node group name outputs must follow input variables"
  }

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0" && length(output.private_subnet_ids) == 3 && length(output.public_subnet_ids) == 3
    error_message = "VPC outputs must pass through the core-vpc remote state"
  }
}

run "apply_wires_secrets_encryption_key" {
  command = apply

  assert {
    condition     = output.eks_secrets_kms_key_arn == "arn:aws:kms:eu-west-2:111122223333:key/11111111-2222-3333-4444-555555555555"
    error_message = "eks_secrets_kms_key_arn output must be the KMS key ARN"
  }

  assert {
    condition     = aws_eks_cluster.main.encryption_config[0].provider[0].key_arn == aws_kms_key.eks_secrets.arn
    error_message = "Cluster secrets encryption must use the dedicated KMS key"
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.eks_cluster_secrets_kms.policy).Statement[0].Resource == aws_kms_key.eks_secrets.arn
    error_message = "Cluster role KMS permissions must be scoped to the secrets key"
  }

  assert {
    condition     = contains(jsondecode(aws_iam_role_policy.eks_cluster_secrets_kms.policy).Statement[0].Action, "kms:Decrypt")
    error_message = "Cluster role must be allowed to decrypt with the secrets KMS key"
  }

  assert {
    condition     = aws_kms_alias.eks_secrets.target_key_id == "11111111-2222-3333-4444-555555555555"
    error_message = "KMS alias must target the secrets key"
  }
}

run "apply_addons_use_latest_version_and_pod_identity" {
  command = apply

  assert {
    condition     = output.ebs_csi_addon_latest_version == "v1.0.0-eksbuild.1" && aws_eks_addon.ebs_csi.addon_version == "v1.0.0-eksbuild.1"
    error_message = "EBS CSI addon must be installed at the most_recent compatible version"
  }

  assert {
    condition     = aws_eks_addon.podidentity.addon_version == output.pod_identity_agent_eksaddon_lastest_version
    error_message = "Pod identity agent addon must be installed at the most_recent compatible version"
  }

  assert {
    condition     = output.lbc_pod_identity_association_arn != "" && output.ebs_csi_pod_identity_association_arn != ""
    error_message = "Pod identity association ARNs must be exported"
  }

  assert {
    condition     = aws_eks_pod_identity_association.lbc.role_arn == aws_iam_role.lbc_iam_role.arn && aws_eks_pod_identity_association.ebs_csi.role_arn == aws_iam_role.ebs_csi_iam_role.arn
    error_message = "Pod identity associations must reference their dedicated IAM roles"
  }

  assert {
    condition     = jsondecode(aws_iam_policy.lbc_iam_policy.policy).Version == "2012-10-17"
    error_message = "LBC IAM policy must be the JSON document fetched from the upstream repository"
  }
}
