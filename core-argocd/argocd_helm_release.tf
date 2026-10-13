locals {
  argocd_domain = "${var.argocd_subdomain}.${trimsuffix(data.terraform_remote_state.route53.outputs.zone_name, ".")}"
  ecr_registry  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"

  app_of_apps = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "root-applications"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repository_url
        targetRevision = var.git_target_revision
        path           = var.gitops_path
        directory = {
          recurse = true
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true
  wait             = true
  timeout          = 900

  values = [yamlencode({
    global = {
      domain = local.argocd_domain
    }
    configs = {
      params = {
        "server.insecure" = true
      }
      repositories = {
        sftpgo-ecr = {
          name      = "sftpgo-ecr"
          type      = "helm"
          url       = local.ecr_registry
          # The chart renders repository properties as base64 strings. Argo CD
          # accepts enableOCI as the string "true" in repository secrets.
          enableOCI = "true"
          username  = data.aws_ecr_authorization_token.sftpgo.user_name
          password  = data.aws_ecr_authorization_token.sftpgo.password
        }
      }
    }
    server = {
      ingress = {
        enabled          = true
        controller       = "generic"
        ingressClassName = "alb"
        hostname         = local.argocd_domain
        annotations = {
          "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"     = "ip"
          "alb.ingress.kubernetes.io/group.name"      = "argocd"
          "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
          "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
          "alb.ingress.kubernetes.io/ssl-policy"      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
          "alb.ingress.kubernetes.io/certificate-arn" = data.terraform_remote_state.acm.outputs.certificate_arn
          "external-dns.alpha.kubernetes.io/hostname" = local.argocd_domain
        }
        tls = false
      }
    }
    extraObjects = [local.app_of_apps]
  })]
}
