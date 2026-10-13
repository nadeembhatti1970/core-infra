mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "042170206259"
      arn        = "arn:aws:iam::042170206259:user/terraform-test"
      user_id    = "AIDAEXAMPLE"
    }
  }

  mock_data "aws_eks_cluster_auth" {
    defaults = {
      token = "mock-eks-token"
    }
  }

  mock_data "aws_ecr_authorization_token" {
    defaults = {
      user_name = "AWS"
      password  = "mock-ecr-password"
    }
  }
}

mock_provider "helm" {}

override_data {
  target = data.terraform_remote_state.eks
  values = {
    outputs = {
      eks_cluster_name                       = "devops-dev-eks"
      eks_cluster_endpoint                   = "https://example.eks.eu-west-2.amazonaws.com"
      eks_cluster_certificate_authority_data = "bW9jay1jYQ=="
    }
  }
}

override_data {
  target = data.terraform_remote_state.route53
  values = {
    outputs = {
      zone_name = "bizopensource.com."
    }
  }
}

override_data {
  target = data.terraform_remote_state.acm
  values = {
    outputs = {
      certificate_arn = "arn:aws:acm:eu-west-2:042170206259:certificate/test-certificate"
    }
  }
}

variables {
  git_repository_url = "https://github.com/example/sftpgo.git"
}

run "argocd_endpoint_uses_route53_zone" {
  command = plan

  assert {
    condition     = local.argocd_domain == "argocd.bizopensource.com"
    error_message = "Argo CD hostname must use the zone name from core-route53."
  }

  assert {
    condition     = output.argocd_url == "https://argocd.bizopensource.com"
    error_message = "Argo CD output must expose the Route 53 hostname over HTTPS."
  }
}

run "root_application_tracks_gitops_directory" {
  command = plan

  assert {
    condition     = local.app_of_apps.spec.source.path == "core-sftpgo/argocd/apps" && local.app_of_apps.spec.source.directory.recurse
    error_message = "The root Argo CD application must recursively sync the configured App of Apps path."
  }

  assert {
    condition     = helm_release.argocd.namespace == "argocd" && helm_release.argocd.chart == "argo-cd"
    error_message = "Argo CD must be installed from the argo-cd chart into its own namespace."
  }
}
