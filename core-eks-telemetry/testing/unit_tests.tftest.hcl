# --------------------------------------------------------------------
# Unit tests: plan-only against mocked AWS, Helm and Kubernetes providers
# (no credentials or cluster access needed). The core-eks and core-vpc
# remote states, caller identity and EKS addon versions are overridden
# with fixed values. Computed ARNs are mocked during plan so IAM policy
# documents can be asserted on.
# --------------------------------------------------------------------
mock_provider "aws" {
  override_during = plan

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:user/terraform"
      user_id    = "AIDAEXAMPLE"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_eks_cluster_auth" {
    defaults = {
      token = "mock-token"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PodIdentity\",\"Effect\":\"Allow\",\"Action\":[\"sts:AssumeRole\",\"sts:TagSession\"],\"Principal\":{\"Service\":\"pods.eks.amazonaws.com\"}}]}"
    }
  }

  mock_data "aws_eks_addon_version" {
    defaults = {
      version = "v0.0.1-eksbuild.1"
    }
  }
}

mock_provider "helm" {}

mock_provider "kubernetes" {}

override_data {
  target = data.terraform_remote_state.eks
  values = {
    outputs = {
      eks_cluster_name                       = "devops-dev-eks"
      eks_cluster_id                         = "devops-dev-eks"
      eks_cluster_version                    = "1.33"
      eks_cluster_endpoint                   = "https://ABCDEF0123456789.gr7.eu-west-2.eks.amazonaws.com"
      eks_cluster_certificate_authority_data = "bW9jay1jYQ=="
    }
  }
}

override_data {
  target = data.terraform_remote_state.vpc
  values = {
    outputs = {
      vpc_id             = "vpc-0123456789abcdef0"
      private_subnet_ids = ["subnet-0aaaaaaaaaaaaaaa1", "subnet-0aaaaaaaaaaaaaaa2"]
      public_subnet_ids  = ["subnet-0bbbbbbbbbbbbbbb1", "subnet-0bbbbbbbbbbbbbbb2"]
    }
  }
}

override_data {
  target = data.aws_iam_policy.xray_readonly
  values = {
    arn = "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
  }
}

override_data {
  target = data.aws_eks_addon_version.adot_latest
  values = {
    version = "v0.131.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.cert_manager_latest
  values = {
    version = "v1.18.2-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.kube_state_metrics_latest
  values = {
    version = "v2.16.0-eksbuild.1"
  }
}

override_data {
  target = data.aws_eks_addon_version.prometheus_node_exporter_latest
  values = {
    version = "v1.9.1-eksbuild.1"
  }
}

override_resource {
  override_during = plan
  target          = aws_prometheus_workspace.amp
  values = {
    arn                 = "arn:aws:aps:eu-west-2:111122223333:workspace/ws-00000000-0000-0000-0000-000000000000"
    id                  = "ws-00000000-0000-0000-0000-000000000000"
    prometheus_endpoint = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-00000000-0000-0000-0000-000000000000/"
  }
}

override_resource {
  override_during = plan
  target          = aws_iam_role.amg_iam_role
  values = {
    arn = "arn:aws:iam::111122223333:role/devops-dev-eks-amg-service-role"
  }
}

override_resource {
  override_during = plan
  target          = aws_iam_role.adot_collector
  values = {
    arn = "arn:aws:iam::111122223333:role/devops-dev-eks-adot-collector-role"
  }
}

override_resource {
  override_during = plan
  target          = aws_iam_policy.adot_collector
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-adot-collector-policy"
  }
}

override_resource {
  override_during = plan
  target          = aws_iam_policy.amg_prometheus_policy
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-prometheus-policy"
  }
}

override_resource {
  override_during = plan
  target          = aws_iam_policy.amg_sns_policy
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-sns-policy"
  }
}

variables {
  aws_region        = "eu-west-2"
  environment_name  = "dev"
  business_division = "devops"
  tags = {
    Terraform = "true"
  }
}

run "amp_workspace_alias_follows_cluster_name" {
  command = plan

  assert {
    condition     = aws_prometheus_workspace.amp.alias == "devops-dev-eks-amp"
    error_message = "AMP workspace alias must be <eks_cluster_name>-amp"
  }

  assert {
    condition     = aws_prometheus_workspace.amp.tags["Terraform"] == "true"
    error_message = "var.tags must be applied to the AMP workspace"
  }
}

run "grafana_workspace_uses_sso_and_customer_managed_role" {
  command = plan

  assert {
    condition     = aws_grafana_workspace.main.name == "devops-dev-eks-amg"
    error_message = "Grafana workspace name must be <eks_cluster_name>-amg"
  }

  assert {
    condition     = aws_grafana_workspace.main.authentication_providers == tolist(["AWS_SSO"])
    error_message = "Grafana workspace must authenticate only via AWS IAM Identity Center (AWS_SSO)"
  }

  assert {
    condition     = aws_grafana_workspace.main.permission_type == "CUSTOMER_MANAGED"
    error_message = "Grafana workspace permission type must be CUSTOMER_MANAGED"
  }

  assert {
    condition     = aws_grafana_workspace.main.account_access_type == "CURRENT_ACCOUNT"
    error_message = "Grafana workspace must only access the current account"
  }

  assert {
    condition     = aws_grafana_workspace.main.role_arn == "arn:aws:iam::111122223333:role/devops-dev-eks-amg-service-role"
    error_message = "Grafana workspace must use the AMG service role defined in this project"
  }
}

run "grafana_workspace_data_sources_and_alerting" {
  command = plan

  assert {
    condition     = toset(aws_grafana_workspace.main.data_sources) == toset(["PROMETHEUS", "CLOUDWATCH", "XRAY"])
    error_message = "Grafana data sources must be exactly PROMETHEUS, CLOUDWATCH and XRAY"
  }

  assert {
    condition     = aws_grafana_workspace.main.notification_destinations == tolist(["SNS"])
    error_message = "Grafana notification destination must be SNS"
  }

  assert {
    condition     = jsondecode(aws_grafana_workspace.main.configuration).unifiedAlerting.enabled == true
    error_message = "Grafana unified alerting must be enabled"
  }

  assert {
    condition     = jsondecode(aws_grafana_workspace.main.configuration).plugins.pluginAdminEnabled == true
    error_message = "Grafana plugin admin must be enabled"
  }
}

run "iam_roles_trust_expected_service_principals" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role.amg_iam_role.assume_role_policy).Statement[0].Principal.Service == "grafana.amazonaws.com"
    error_message = "AMG service role must only be assumable by grafana.amazonaws.com"
  }

  assert {
    condition     = aws_iam_role.adot_collector.name == "devops-dev-eks-adot-collector-role"
    error_message = "ADOT collector role name must be <eks_cluster_name>-adot-collector-role"
  }

  assert {
    condition     = one(data.aws_iam_policy_document.adot_collector_assume.statement[0].principals).identifiers == toset(["pods.eks.amazonaws.com"])
    error_message = "ADOT collector role must trust the EKS Pod Identity service principal"
  }

  assert {
    condition     = toset(data.aws_iam_policy_document.adot_collector_assume.statement[0].actions) == toset(["sts:AssumeRole", "sts:TagSession"])
    error_message = "Pod Identity trust must allow sts:AssumeRole and sts:TagSession"
  }
}

run "iam_policies_scope_prometheus_access_to_workspace" {
  command = plan

  assert {
    condition = anytrue([
      for s in jsondecode(aws_iam_policy.adot_collector.policy).Statement :
      contains(s.Action, "aps:RemoteWrite") && s.Resource == "arn:aws:aps:eu-west-2:111122223333:workspace/ws-00000000-0000-0000-0000-000000000000"
    ])
    error_message = "ADOT collector aps:RemoteWrite must be scoped to the AMP workspace ARN"
  }

  assert {
    condition = alltrue([
      for s in jsondecode(aws_iam_policy.amg_prometheus_policy.policy).Statement :
      s.Resource == "arn:aws:aps:eu-west-2:111122223333:workspace/ws-00000000-0000-0000-0000-000000000000" || s.Action == ["aps:ListWorkspaces"]
    ])
    error_message = "AMG Prometheus policy may only use Resource \"*\" for aps:ListWorkspaces; all other actions must target the AMP workspace"
  }

  assert {
    condition = alltrue(flatten([
      for s in jsondecode(aws_iam_policy.adot_collector.policy).Statement : [
        for r in flatten([s.Resource]) : startswith(r, "arn:aws:logs:eu-west-2:111122223333:log-group:/aws/")
      ] if anytrue([for a in s.Action : startswith(a, "logs:")])
    ]))
    error_message = "ADOT collector CloudWatch Logs actions must be limited to /aws/* log groups in this account and region"
  }

  assert {
    condition     = jsondecode(aws_iam_policy.amg_sns_policy.policy).Statement[0].Resource == ["arn:aws:sns:*:111122223333:grafana*"]
    error_message = "AMG SNS publish must be limited to grafana* topics in this account"
  }
}

run "iam_policies_attached_to_roles" {
  command = plan

  assert {
    condition     = aws_iam_role_policy_attachment.adot_collector.role == "devops-dev-eks-adot-collector-role" && aws_iam_role_policy_attachment.adot_collector.policy_arn == "arn:aws:iam::111122223333:policy/devops-dev-adot-collector-policy"
    error_message = "ADOT collector policy must be attached to the ADOT collector role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.amg_prometheus_policy_attachment.role == "devops-dev-eks-amg-service-role" && aws_iam_role_policy_attachment.amg_prometheus_policy_attachment.policy_arn == "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-prometheus-policy"
    error_message = "AMG Prometheus policy must be attached to the AMG service role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.amg_sns_policy_attachment.policy_arn == "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-sns-policy"
    error_message = "AMG SNS policy must be attached to the AMG service role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.amg_xray_readonly_attachment.policy_arn == "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess"
    error_message = "AWS managed AWSXrayReadOnlyAccess must be attached to the AMG service role"
  }
}

run "pod_identity_association_binds_collector_service_account" {
  command = plan

  assert {
    condition     = aws_eks_pod_identity_association.adot_collector.cluster_name == "devops-dev-eks"
    error_message = "Pod identity association must target the core-eks cluster"
  }

  assert {
    condition     = aws_eks_pod_identity_association.adot_collector.namespace == kubernetes_service_account_v1.adot_collector.metadata[0].namespace
    error_message = "Pod identity namespace must match the ADOT collector ServiceAccount namespace"
  }

  assert {
    condition     = aws_eks_pod_identity_association.adot_collector.service_account == kubernetes_service_account_v1.adot_collector.metadata[0].name
    error_message = "Pod identity service account must match the ADOT collector ServiceAccount name"
  }

  assert {
    condition     = aws_eks_pod_identity_association.adot_collector.role_arn == "arn:aws:iam::111122223333:role/devops-dev-eks-adot-collector-role"
    error_message = "Pod identity association must use the ADOT collector IAM role"
  }
}

run "eks_addons_use_latest_compatible_versions" {
  command = plan

  assert {
    condition     = aws_eks_addon.adot.addon_name == "adot" && aws_eks_addon.adot.addon_version == "v0.131.0-eksbuild.1"
    error_message = "ADOT addon must use the most recent compatible version"
  }

  assert {
    condition     = aws_eks_addon.cert_manager.addon_name == "cert-manager" && aws_eks_addon.cert_manager.addon_version == "v1.18.2-eksbuild.1"
    error_message = "cert-manager addon must use the most recent compatible version"
  }

  assert {
    condition     = aws_eks_addon.kube_state_metrics.addon_name == "kube-state-metrics" && aws_eks_addon.kube_state_metrics.addon_version == "v2.16.0-eksbuild.1"
    error_message = "kube-state-metrics addon must use the most recent compatible version"
  }

  assert {
    condition     = aws_eks_addon.prometheus_node_exporter.addon_name == "prometheus-node-exporter" && aws_eks_addon.prometheus_node_exporter.addon_version == "v1.9.1-eksbuild.1"
    error_message = "prometheus-node-exporter addon must use the most recent compatible version"
  }

  assert {
    condition = alltrue([
      for a in [aws_eks_addon.adot, aws_eks_addon.cert_manager, aws_eks_addon.kube_state_metrics, aws_eks_addon.prometheus_node_exporter] :
      a.cluster_name == "devops-dev-eks" && a.resolve_conflicts_on_create == "OVERWRITE" && a.resolve_conflicts_on_update == "OVERWRITE"
    ])
    error_message = "All EKS addons must target the core-eks cluster and OVERWRITE conflicts on create/update"
  }

  assert {
    condition     = jsondecode(aws_eks_addon.adot.configuration_values).replicaCount == 1 && jsondecode(aws_eks_addon.adot.configuration_values).manager.resources.limits.memory == "256Mi"
    error_message = "ADOT addon configuration must set 1 replica and a 256Mi memory limit"
  }
}

run "collector_rbac_grants_read_only_cluster_access" {
  command = plan

  assert {
    condition     = kubernetes_cluster_role_binding_v1.otel_collector.role_ref[0].kind == "ClusterRole" && kubernetes_cluster_role_binding_v1.otel_collector.role_ref[0].name == "otel-collector-cluster-role"
    error_message = "Cluster role binding must reference the otel-collector ClusterRole"
  }

  assert {
    condition     = kubernetes_cluster_role_binding_v1.otel_collector.subject[0].kind == "ServiceAccount" && kubernetes_cluster_role_binding_v1.otel_collector.subject[0].name == "adot-collector" && kubernetes_cluster_role_binding_v1.otel_collector.subject[0].namespace == "default"
    error_message = "Cluster role binding must bind the adot-collector ServiceAccount in its namespace"
  }

  assert {
    condition = alltrue(flatten([
      for r in kubernetes_cluster_role_v1.otel_collector.rule :
      [for v in r.verbs : contains(["get", "list", "watch"], v)]
    ]))
    error_message = "OTel collector ClusterRole must be read-only (get/list/watch)"
  }

  assert {
    condition     = anytrue([for r in kubernetes_cluster_role_v1.otel_collector.rule : contains(coalesce(r.non_resource_urls, []), "/metrics")])
    error_message = "OTel collector ClusterRole must allow GET on /metrics"
  }
}
