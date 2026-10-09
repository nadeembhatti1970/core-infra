# AWS Region and Environment
aws_region        = "eu-west-2"
environment_name  = "dev"
business_division = "devops"

# EKS Cluster 
cluster_name              = "dev-eks-cluster"
cluster_service_ipv4_cidr = "172.20.0.0/16"
cluster_version           = "1.36"

# EKS Cluster Access Control
cluster_endpoint_private_access      = false
cluster_endpoint_public_access       = true
cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

# EKS Node Group Configuration
node_instance_types = ["t3.medium"] # Replace with desired types
node_capacity_type  = "ON_DEMAND"   # or "SPOT"
node_disk_size      = 20


