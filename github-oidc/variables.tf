# --------------------------------------------------------
# AWS Region (used in provider block)
# --------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-2"
}

# --------------------------------------------------------
# Environment & Business Division Info
# --------------------------------------------------------

# Logical environment name (used in tags and resource names)
variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

# Business unit or department (used in tags and naming)
variable "business_division" {
  description = "Business Division in the large organization this infrastructure belongs to"
  type        = string
  default     = "devops"
}

# --------------------------------------------------------
# GitHub Configuration
# --------------------------------------------------------

# Repository allowed to assume the roles, as "<owner>/<repo>"
variable "github_repository" {
  description = "GitHub repository (owner/name) whose Actions workflows may assume the roles"
  type        = string
  default     = "nadeembhatti1970/core-infra"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must be in the form <owner>/<repo>."
  }
}

# Immutable GitHub OIDC subject identifiers for this repository.
# GitHub includes these IDs in the default sub claim for repositories created after 2026-07-15.
variable "github_repository_owner_id" {
  description = "Immutable GitHub user or organization ID used in OIDC subject claims"
  type        = string
  default     = "13079239"
}

variable "github_repository_id" {
  description = "Immutable GitHub repository ID used in OIDC subject claims"
  type        = string
  default     = "1399975654"
}

# Only workflows running on this branch may assume the apply role
variable "apply_branch" {
  description = "Git branch whose workflows (push/merge, schedule, dispatch) may assume the apply role"
  type        = string
  default     = "main"
}

# --------------------------------------------------------
# Terraform State
# --------------------------------------------------------

# S3 bucket holding every project's remote state (see s3-remote-backend)
variable "tfstate_bucket_name" {
  description = "Name of the S3 bucket used as the Terraform remote backend"
  type        = string
  default     = "tfstate-dev-eu-west-2-8cbztj"
}

# Session length for the GitHub Actions roles (EKS create/destroy can exceed 1 hour)
variable "max_session_duration" {
  description = "Maximum session duration in seconds for the GitHub Actions roles"
  type        = number
  default     = 7200

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

# --------------------------------------------------------
# Common Tags
# --------------------------------------------------------

# Tags applied to all resources created by this configuration
variable "tags" {
  description = "Tags to apply to GitHub OIDC resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
