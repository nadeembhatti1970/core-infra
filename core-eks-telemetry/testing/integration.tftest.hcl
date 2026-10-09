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
  target = aws_prometheus_workspace.amp
  values = {
    arn                 = "arn:aws:aps:eu-west-2:111122223333:workspace/ws-00000000-0000-0000-0000-000000000000"
    id                  = "ws-00000000-0000-0000-0000-000000000000"
    prometheus_endpoint = "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-00000000-0000-0000-0000-000000000000/"
  }
}

override_resource {
  target = aws_iam_role.amg_iam_role
  values = {
    arn = "arn:aws:iam::111122223333:role/devops-dev-eks-amg-service-role"
  }
}

override_resource {
  target = aws_iam_role.adot_collector
  values = {
    arn = "arn:aws:iam::111122223333:role/devops-dev-eks-adot-collector-role"
  }
}

override_resource {
  target = aws_iam_policy.adot_collector
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-adot-collector-policy"
  }
}

override_resource {
  target = aws_iam_policy.amg_prometheus_policy
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-prometheus-policy"
  }
}

override_resource {
  target = aws_iam_policy.amg_sns_policy
  values = {
    arn = "arn:aws:iam::111122223333:policy/devops-dev-eks-amg-sns-policy"
  }
}

override_resource {
  target = aws_grafana_workspace.main
  values = {
    id       = "g-0123456789"
    arn      = "arn:aws:grafana:eu-west-2:111122223333:/workspaces/g-0123456789"
    endpoint = "g-0123456789.grafana-workspace.eu-west-2.amazonaws.com"
  }
}

variables {
  aws_region        = "eu-west-2"
  environment_name  = "dev"
  business_division = "devops"
}

run "apply_outputs_amp_endpoints" {
  command = apply

  assert {
    condition     = output.amp_workspace_id == "ws-00000000-0000-0000-0000-000000000000"
    error_message = "amp_workspace_id output must come from the AMP workspace"
  }

  assert {
    condition     = output.amp_endpoint == "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-00000000-0000-0000-0000-000000000000/api/v1/remote_write"
    error_message = "amp_endpoint output must be the workspace remote_write URL"
  }

  assert {
    condition     = output.amp_query_endpoint == "https://aps-workspaces.eu-west-2.amazonaws.com/workspaces/ws-00000000-0000-0000-0000-000000000000/api/v1/query"
    error_message = "amp_query_endpoint output must be the workspace query URL"
  }
}

run "apply_outputs_grafana_and_iam" {
  command = apply

  assert {
    condition     = output.amg_workspace_url == "https://g-0123456789.grafana-workspace.eu-west-2.amazonaws.com"
    error_message = "amg_workspace_url output must be https:// plus the Grafana workspace endpoint"
  }

  assert {
    condition     = output.amg_workspace_id == "g-0123456789" && output.amg_workspace_arn == "arn:aws:grafana:eu-west-2:111122223333:/workspaces/g-0123456789"
    error_message = "Grafana workspace id/arn outputs must come from the workspace"
  }

  assert {
    condition     = output.amg_iam_role_arn == "arn:aws:iam::111122223333:role/devops-dev-eks-amg-service-role" && output.amg_iam_role_name == "devops-dev-eks-amg-service-role"
    error_message = "AMG role outputs must expose the AMG service role"
  }

  assert {
    condition     = output.adot_collector_role_arn == "arn:aws:iam::111122223333:role/devops-dev-eks-adot-collector-role"
    error_message = "adot_collector_role_arn output must expose the ADOT collector role"
  }

  assert {
    condition     = jsondecode(aws_iam_policy.adot_collector.policy).Statement[4].Resource == aws_prometheus_workspace.amp.arn
    error_message = "Applied ADOT collector policy must scope AMP access to the created workspace ARN"
  }
}

run "apply_outputs_addons_and_remote_state" {
  command = apply

  assert {
    condition     = output.adot_addon_version == "v0.131.0-eksbuild.1"
    error_message = "adot_addon_version output must equal the latest compatible ADOT version"
  }

  assert {
    condition     = output.kube_state_metrics_version == "v2.16.0-eksbuild.1"
    error_message = "kube_state_metrics_version output must equal the latest compatible version"
  }

  assert {
    condition     = output.prometheus_node_exporter_addon_version == "v1.9.1-eksbuild.1"
    error_message = "prometheus_node_exporter_addon_version output must equal the latest compatible version"
  }

  assert {
    condition     = output.eks_cluster_name == "devops-dev-eks" && output.eks_cluster_id == "devops-dev-eks"
    error_message = "EKS cluster outputs must be passed through from core-eks remote state"
  }

  assert {
    condition     = output.vpc_id == "vpc-0123456789abcdef0" && length(output.private_subnet_ids) == 2 && length(output.public_subnet_ids) == 2
    error_message = "VPC outputs must be passed through from core-vpc remote state"
  }
}
