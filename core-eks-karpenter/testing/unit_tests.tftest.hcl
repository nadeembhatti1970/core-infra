# --------------------------------------------------------------------
# Unit tests: plan-only against mocked AWS, Helm and Kubernetes providers
# (no credentials or cluster access needed).
# The core-eks and core-vpc remote states are overridden with fixed values.
# --------------------------------------------------------------------
mock_provider "aws" {
  override_during = plan

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

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/mocked-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::111122223333:policy/mocked-policy"
    }
  }

  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:eu-west-2:111122223333:devops-dev-eksdemo"
      url = "https://sqs.eu-west-2.amazonaws.com/111122223333/devops-dev-eksdemo"
    }
  }
}

mock_provider "helm" {}

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

variables {
  aws_region        = "eu-west-2"
  environment_name  = "dev"
  business_division = "devops"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

run "iam_roles_follow_naming_convention" {
  command = plan

  assert {
    condition     = aws_iam_role.karpenter_controller.name == "devops-dev-karpenter-controller-role"
    error_message = "Controller role name must be <business_division>-<environment_name>-karpenter-controller-role"
  }

  assert {
    condition     = aws_iam_role.karpenter_node.name == "devops-dev-karpenter-node-role"
    error_message = "Node role name must be <business_division>-<environment_name>-karpenter-node-role"
  }

  assert {
    condition     = aws_iam_policy.karpenter_controller.name == "devops-dev-karpenter-controller-policy"
    error_message = "Controller policy name must be <business_division>-<environment_name>-karpenter-controller-policy"
  }

  assert {
    condition     = aws_iam_role.karpenter_controller.tags["Terraform"] == "true" && aws_iam_role.karpenter_node.tags["Environment"] == "dev"
    error_message = "var.tags must be applied to the Karpenter IAM roles"
  }
}

run "iam_trust_policies_target_correct_services" {
  command = plan

  assert {
    condition     = contains(flatten([for p in data.aws_iam_policy_document.karpenter_controller_assume.statement[0].principals : p.identifiers]), "pods.eks.amazonaws.com")
    error_message = "Controller role must be assumable by EKS Pod Identity (pods.eks.amazonaws.com)"
  }

  assert {
    condition     = toset(data.aws_iam_policy_document.karpenter_controller_assume.statement[0].actions) == toset(["sts:AssumeRole", "sts:TagSession"])
    error_message = "Pod Identity trust must allow sts:AssumeRole and sts:TagSession"
  }

  assert {
    condition     = contains(flatten([for p in data.aws_iam_policy_document.node_assume.statement[0].principals : p.identifiers]), "ec2.amazonaws.com")
    error_message = "Node role must be assumable by EC2 instances launched by Karpenter"
  }
}

run "node_role_has_required_managed_policies" {
  command = plan

  assert {
    condition     = length(aws_iam_role_policy_attachment.node_base_policies) == 4
    error_message = "Node role must have exactly 4 base managed policies attached"
  }

  assert {
    condition = alltrue([
      for arn in [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      ] : contains(keys(aws_iam_role_policy_attachment.node_base_policies), arn)
    ])
    error_message = "Node role must attach WorkerNode, ECR PullOnly, CNI and SSM managed policies"
  }

  assert {
    condition     = alltrue([for a in aws_iam_role_policy_attachment.node_base_policies : a.role == "devops-dev-karpenter-node-role"])
    error_message = "All base policy attachments must target the Karpenter node role"
  }
}

run "controller_policy_is_scoped_to_cluster_and_queue" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.karpenter_controller_attach.role == "devops-dev-karpenter-controller-role"
    error_message = "Controller policy must be attached to the Karpenter controller role"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.karpenter_controller.statement :
      s.sid == "AllowInterruptionQueueActions" && contains(s.resources, "arn:aws:sqs:eu-west-2:111122223333:devops-dev-eksdemo")
    ])
    error_message = "Controller policy must grant SQS actions only on the interruption queue ARN"
  }

  assert {
    condition = anytrue([
      for s in data.aws_iam_policy_document.karpenter_controller.statement :
      s.sid == "AllowAPIServerEndpointDiscovery" && contains(s.resources, "arn:aws:eks:eu-west-2:111122223333:cluster/devops-dev-eksdemo")
    ])
    error_message = "eks:DescribeCluster must be scoped to the remote-state cluster in the current account/region"
  }
}

run "sqs_interruption_queue_is_encrypted_and_short_lived" {
  command = plan

  assert {
    condition     = aws_sqs_queue.karpenter_interruption.name == "devops-dev-eksdemo"
    error_message = "Interruption queue must be named after the EKS cluster"
  }

  assert {
    condition     = aws_sqs_queue.karpenter_interruption.sqs_managed_sse_enabled == true
    error_message = "Interruption queue must use SQS-managed server-side encryption"
  }

  assert {
    condition     = aws_sqs_queue.karpenter_interruption.message_retention_seconds == 300
    error_message = "Interruption queue retention must be 300 seconds (stale interruption events are useless)"
  }

  assert {
    condition     = jsondecode(aws_sqs_queue_policy.karpenter_interruption.policy).Statement[1].Effect == "Deny" && jsondecode(aws_sqs_queue_policy.karpenter_interruption.policy).Statement[1].Condition.Bool["aws:SecureTransport"] == "false"
    error_message = "Queue policy must deny non-TLS access"
  }

  assert {
    condition     = contains(jsondecode(aws_sqs_queue_policy.karpenter_interruption.policy).Statement[0].Principal.Service, "events.amazonaws.com")
    error_message = "Queue policy must allow EventBridge to send messages"
  }
}

run "eventbridge_rules_route_events_to_queue" {
  command = plan

  assert {
    condition = toset([
      aws_cloudwatch_event_rule.karpenter_health_event.name,
      aws_cloudwatch_event_rule.karpenter_spot_interrupt.name,
      aws_cloudwatch_event_rule.karpenter_rebalance.name,
      aws_cloudwatch_event_rule.karpenter_instance_state.name,
      ]) == toset([
      "devops-dev-eksdemo-k-health",
      "devops-dev-eksdemo-k-spot",
      "devops-dev-eksdemo-k-rebal",
      "devops-dev-eksdemo-k-state",
    ])
    error_message = "EventBridge rule names must be <cluster_name>-k-<type>"
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.karpenter_spot_interrupt.event_pattern)["detail-type"][0] == "EC2 Spot Instance Interruption Warning"
    error_message = "Spot rule must match EC2 Spot Instance Interruption Warning events"
  }

  assert {
    condition     = jsondecode(aws_cloudwatch_event_rule.karpenter_health_event.event_pattern).source[0] == "aws.health"
    error_message = "Health rule must match aws.health events"
  }

  assert {
    condition = alltrue([
      for t in [
        aws_cloudwatch_event_target.karpenter_health_target,
        aws_cloudwatch_event_target.karpenter_spot_target,
        aws_cloudwatch_event_target.karpenter_rebalance_target,
        aws_cloudwatch_event_target.karpenter_instance_state_target,
      ] : t.arn == "arn:aws:sqs:eu-west-2:111122223333:devops-dev-eksdemo"
    ])
    error_message = "All EventBridge targets must deliver to the Karpenter interruption queue"
  }
}

run "eventbridge_rule_names_truncate_long_cluster_names" {
  command = plan

  override_data {
    target = data.terraform_remote_state.eks
    values = {
      outputs = {
        eks_cluster_name                       = "devops-prod-very-long-eks-cluster-name"
        eks_cluster_id                         = "devops-prod-very-long-eks-cluster-name"
        eks_cluster_endpoint                   = "https://ABCDEF0123456789.gr7.eu-west-2.eks.amazonaws.com"
        eks_cluster_certificate_authority_data = "bW9ja2VkLWNh"
      }
    }
  }

  assert {
    condition     = aws_cloudwatch_event_rule.karpenter_instance_state.name == "devops-prod-very-lon-k-state"
    error_message = "Cluster name must be truncated to 20 chars in EventBridge rule names (64-char limit)"
  }

  assert {
    condition     = aws_sqs_queue.karpenter_interruption.name == "devops-prod-very-long-eks-cluster-name"
    error_message = "Queue name must keep the full cluster name"
  }
}

run "pod_identity_and_access_entry_wire_up_cluster" {
  command = plan

  assert {
    condition     = aws_eks_pod_identity_association.karpenter.cluster_name == "devops-dev-eksdemo" && aws_eks_pod_identity_association.karpenter.namespace == "kube-system" && aws_eks_pod_identity_association.karpenter.service_account == "karpenter"
    error_message = "Pod Identity association must bind kube-system/karpenter on the remote-state cluster"
  }

  assert {
    condition     = aws_eks_access_entry.karpenter_node_access.type == "EC2_LINUX"
    error_message = "Node access entry must be of type EC2_LINUX so Karpenter nodes can join"
  }

  assert {
    condition     = aws_eks_access_entry.karpenter_node_access.cluster_name == "devops-dev-eksdemo"
    error_message = "Node access entry must target the remote-state cluster"
  }
}

run "helm_release_installs_pinned_karpenter_chart" {
  command = plan

  assert {
    condition     = helm_release.karpenter.chart == "karpenter" && helm_release.karpenter.version == "1.8.2"
    error_message = "Karpenter chart must be pinned to version 1.8.2"
  }

  assert {
    condition     = helm_release.karpenter.namespace == "kube-system" && helm_release.karpenter.create_namespace == false
    error_message = "Karpenter must be installed into the existing kube-system namespace"
  }

  assert {
    condition     = { for s in helm_release.karpenter.set : s.name => s.value }["settings.clusterName"] == "devops-dev-eksdemo"
    error_message = "settings.clusterName must come from the core-eks remote state"
  }

  assert {
    condition     = { for s in helm_release.karpenter.set : s.name => s.value }["settings.interruptionQueue"] == "devops-dev-eksdemo"
    error_message = "settings.interruptionQueue must be the interruption SQS queue name"
  }

  assert {
    condition     = { for s in helm_release.karpenter.set : s.name => s.value }["serviceAccount.name"] == "karpenter"
    error_message = "Helm service account name must match the Pod Identity association"
  }
}
