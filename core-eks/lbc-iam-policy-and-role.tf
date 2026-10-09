
# Resource: Create AWS Load Balancer Controller IAM Policy 
resource "aws_iam_policy" "lbc_iam_policy" {
  # checkov:skip=CKV_AWS_290: Official AWS Load Balancer Controller policy; it creates ELBs/SGs/target groups whose ARNs are unknown in advance
  # checkov:skip=CKV_AWS_355: Official AWS Load Balancer Controller policy; Describe*/Create* actions require "*" resources
  name        = "${local.name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "AWS Load Balancer Controller IAM Policy"
  policy      = data.http.lbc_iam_policy.response_body
}

output "lbc_iam_policy_arn" {
  value = aws_iam_policy.lbc_iam_policy.arn
}

# Resource: Create IAM Role 
resource "aws_iam_role" "lbc_iam_role" {
  name               = "${local.name}-lbc-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${local.name}-lbc-iam-role"
    Environment = var.environment_name
    Component   = "AWS Load Balancer Controller"
  }
}

# Associate Load Balanacer Controller IAM Policy to  IAM Role
resource "aws_iam_role_policy_attachment" "lbc_iam_role_policy_attach" {
  policy_arn = aws_iam_policy.lbc_iam_policy.arn
  role       = aws_iam_role.lbc_iam_role.name
}

output "lbc_iam_role_arn" {
  description = "AWS Load Balancer Controller IAM Role ARN"
  value       = aws_iam_role.lbc_iam_role.arn
}

