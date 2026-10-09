# --------------------------------------------------------
# AWS Region (used in provider block)
# Certificates must be in the same region as the ALBs that use them.
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
# Certificate Configuration
# --------------------------------------------------------

# Extra names on the certificate in addition to the zone apex.
# The wildcard covers sftpgo.<domain> and any future single-level subdomains.
variable "subject_alternative_names" {
  description = "Subject alternative names, relative to the zone apex (e.g. \"*\" => *.bizopensource.com)"
  type        = list(string)
  default     = ["*"]
}

# --------------------------------------------------------
# Common Tags
# --------------------------------------------------------

# Tags applied to all resources created by this configuration
variable "tags" {
  description = "Tags to apply to ACM resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
