# --------------------------------------------------------------------
# Integration tests: ephemeral apply against mocked AWS, Helm and
# Kubernetes providers. Exercises computed attributes and outputs
# without touching AWS or the EKS cluster.
# --------------------------------------------------------------------
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:user/terraform"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
      name   = "eu-west-2"
    }
  }

  mock_data "aws_eks_cluster_auth" {
    defaults = {
      token = "k8s-aws-v1.mocked-token"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:eu-west-2:111122223333:devops-dev-eksdemo"
      url = "https://sqs.eu-west-2.amazonaws.com/111122223333/devops-dev-eksdemo"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/devops-dev-karpenter-controller-policy"
    }
  }

  mock_resource "aws_eks_pod_identity_association" {
    defaults = {
      id = "a-0123456789abcdef0"
    }
  }
}

mock_provider "helm" {
  mock_resource "helm_release" {
    defaults = {
      status = "deployed"
    }
  }
}

mock_provider "kubernetes" {}

override_data {
  target = data.terraform_remote_state.eks
  values = {
    outputs = {
      eks_cluster_name                       = "devops-dev-eksdemo"
      eks_cluster_id                         = "devops-dev-eksdemo"
      eks_cluster_endpoint                   = "https://ABCDEF0123456789.gr7.eu-west-2.eks.amazonaws.com"
      eks_cluster_certificate_authority_data = "bW9ja2VkLWNh"
    }
  }
}

override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id             = "vpc-0123456789abcdef0"
      private_subnet_ids = ["subnet-0aaa1111", "subnet-0bbb2222", "subnet-0ccc3333"]
      public_subnet_ids  = ["subnet-0ddd4444", "subnet-0eee5555", "subnet-0fff6666"]
    }
  }
}

override_resource {
  target = aws_iam_role.karpenter_controller
  values = {
    arn = "arn:aws:iam::111122223333:role/devops-dev-karpenter-controller-role"
  }
}

override_resource {
  target = aws_iam_role.karpenter_node
  values = {
    arn       = "arn:aws:iam::111122223333:role/devops-dev-karpenter-node-role"
    unique_id = "AROAEXAMPLEKARPENTER1"
  }
}

variables {
  aws_region        = "eu-west-2"
  environment_name  = "dev"
  business_division = "devops"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

run "apply_exposes_iam_and_cluster_outputs" {
  command = apply

  assert {
    condition     = output.karpenter_controller_role_name == "devops-dev-karpenter-controller-role" && output.karpenter_controller_role_arn == "arn:aws:iam::111122223333:role/devops-dev-karpenter-controller-role"
    error_message = "Controller role outputs must expose the created role name and ARN"
  }

  assert {
    condition     = output.karpenter_node_role_name == "devops-dev-karpenter-node-role" && output.karpenter_node_role_arn == "arn:aws:iam::111122223333:role/devops-dev-karpenter-node-role"
    error_message = "Node role outputs must expose the created role name and ARN (used by EC2NodeClass)"
  }

  assert {
    condition     = output.karpenter_node_role_unique_id == "AROAEXAMPLEKARPENTER1"
    error_message = "karpenter_node_role_unique_id output must expose the node role unique ID"
  }

  assert {
    condition     = output.karpenter_controller_pod_identity_association == "a-0123456789abcdef0"
    error_message = "Pod Identity association output must expose the association ID"
  }

  assert {
    condition     = output.eks_cluster_name == "devops-dev-eksdemo" && output.eks_cluster_id == "devops-dev-eksdemo"
    error_message = "EKS cluster outputs must pass through the core-eks remote state"
  }

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0" && length(output.private_subnet_ids) == 3 && length(output.public_subnet_ids) == 3
    error_message = "VPC outputs must pass through the core-vpc remote state"
  }
}

run "apply_wires_computed_arns_between_resources" {
  command = apply

  assert {
    condition     = aws_eks_pod_identity_association.karpenter.role_arn == aws_iam_role.karpenter_controller.arn
    error_message = "Pod Identity association must use the controller role ARN"
  }

  assert {
    condition     = aws_eks_access_entry.karpenter_node_access.principal_arn == aws_iam_role.karpenter_node.arn
    error_message = "Access entry principal must be the Karpenter node role ARN"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.karpenter_controller_attach.policy_arn == aws_iam_policy.karpenter_controller.arn
    error_message = "Controller policy attachment must reference the created controller policy"
  }

  assert {
    condition     = aws_sqs_queue_policy.karpenter_interruption.queue_url == aws_sqs_queue.karpenter_interruption.url
    error_message = "Queue policy must be attached to the interruption queue URL"
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.karpenter_interruption.policy).Statement[0].Resource == aws_sqs_queue.karpenter_interruption.arn
    error_message = "Queue policy statements must be scoped to the interruption queue ARN"
  }

  assert {
    condition     = aws_iam_service_linked_role.ec2_spot.aws_service_name == "spot.amazonaws.com"
    error_message = "EC2 Spot service-linked role must be created for spot.amazonaws.com"
  }

  assert {
    condition     = helm_release.karpenter.status == "deployed"
    error_message = "Karpenter Helm release must reach deployed status"
  }
}
