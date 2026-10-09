# ------------------------------------------------------------------------------
# KMS Key for EKS Secrets Envelope Encryption
# Kubernetes Secrets stored in etcd are envelope-encrypted with this key.
# NOTE: Once enabled on a cluster, secrets encryption cannot be disabled.
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

resource "aws_kms_key" "eks_secrets" {
  description             = "KMS key for EKS secrets envelope encryption on ${local.eks_cluster_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Key policy: delegate key administration and usage to IAM in this account
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${local.name}-eks-secrets-kms"
    Environment = var.environment_name
    Component   = "EKS Secrets Encryption"
  })
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${local.eks_cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}

# ------------------------------------------------------------------------------
# Allow the EKS control plane role to use the key for envelope encryption
# ------------------------------------------------------------------------------
resource "aws_iam_role_policy" "eks_cluster_secrets_kms" {
  name = "${local.name}-eks-cluster-secrets-kms"
  role = aws_iam_role.eks_cluster.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EksSecretsEnvelopeEncryption"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ListGrants",
          "kms:DescribeKey",
        ]
        Resource = aws_kms_key.eks_secrets.arn
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# Output the KMS key ARN used for EKS secrets encryption
# ------------------------------------------------------------------------------
output "eks_secrets_kms_key_arn" {
  description = "ARN of the KMS key used for EKS secrets envelope encryption"
  value       = aws_kms_key.eks_secrets.arn
}
