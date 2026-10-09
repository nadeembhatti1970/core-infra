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
# DNS Configuration
# --------------------------------------------------------

# Domain registered at IONOS; its name servers must be pointed at this hosted zone
variable "domain_name" {
  description = "Domain name for the public Route53 hosted zone (registered at IONOS)"
  type        = string
  default     = "bizopensource.com"
}

# --------------------------------------------------------
# Common Tags
# --------------------------------------------------------

# Tags applied to all resources created by this configuration
variable "tags" {
  description = "Tags to apply to Route53 resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
