variable "aws_region" {
  description = "AWS region containing the EKS cluster and ACM certificate"
  type        = string
  default     = "eu-west-2"
}

variable "environment_name" {
  description = "Environment name used in remote state paths and tags"
  type        = string
  default     = "dev"
}

variable "business_division" {
  description = "Business division used for resource naming and tags"
  type        = string
  default     = "devops"
}

variable "argocd_subdomain" {
  description = "Subdomain label used for the Argo CD UI under the core-route53 hosted zone"
  type        = string
  default     = "argocd"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.argocd_subdomain))
    error_message = "argocd_subdomain must be a single DNS label."
  }
}

variable "git_repository_url" {
  description = "Git repository URL containing the Argo CD App of Apps manifests"
  type        = string
}

variable "git_target_revision" {
  description = "Git branch, tag, or commit tracked by the App of Apps root application"
  type        = string
  default     = "main"
}

variable "gitops_path" {
  description = "Repository directory containing child Argo CD Application manifests"
  type        = string
  default     = "core-sftpgo/argocd/apps"
}

variable "argocd_chart_version" {
  description = "Pinned version of the upstream argo-cd Helm chart"
  type        = string
  default     = "9.1.0"
}

variable "tags" {
  description = "Common tags retained for consistency with other core-infra projects"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
