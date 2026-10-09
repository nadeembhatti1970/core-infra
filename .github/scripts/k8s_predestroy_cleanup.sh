#!/usr/bin/env bash
# Removes AWS resources created by in-cluster controllers (not tracked by
# Terraform) so that core-eks and core-vpc can be destroyed cleanly:
#   - ALBs/NLBs and security groups created by the AWS Load Balancer Controller
#   - EC2 nodes launched by Karpenter
# Usage: k8s_predestroy_cleanup.sh <cluster-name> <region>
set -euo pipefail
cluster="${1:?cluster name}"
region="${2:?region}"
timeout_s=900

if ! aws eks describe-cluster --name "$cluster" --region "$region" >/dev/null 2>&1; then
  echo "Cluster $cluster not found; nothing to clean up."
  exit 0
fi

aws eks update-kubeconfig --name "$cluster" --region "$region" >/dev/null

echo "Deleting Ingresses and LoadBalancer Services (AWS Load Balancer Controller tears down ALBs/NLBs)..."
kubectl delete ingress --all --all-namespaces --wait=true --timeout=5m || true
kubectl get svc --all-namespaces -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' \
  | while read -r ns name; do
      [ -n "$name" ] && kubectl delete svc "$name" -n "$ns" --wait=true --timeout=5m || true
    done

echo "Deleting Karpenter NodePools (Karpenter terminates the nodes it launched)..."
if kubectl get crd nodepools.karpenter.sh >/dev/null 2>&1; then
  kubectl delete nodepools.karpenter.sh --all --wait=true --timeout=10m || true
fi
# EC2NodeClass deletion makes Karpenter remove the instance profiles it created;
# leftover profiles would block deletion of the Karpenter node IAM role.
if kubectl get crd ec2nodeclasses.karpenter.k8s.aws >/dev/null 2>&1; then
  kubectl delete ec2nodeclasses.karpenter.k8s.aws --all --wait=true --timeout=10m || true
fi

echo "Waiting for controller-managed load balancers and Karpenter instances to disappear..."
deadline=$(( $(date +%s) + timeout_s ))
while :; do
  lbs=$(aws resourcegroupstaggingapi get-resources --region "$region" \
          --resource-type-filters elasticloadbalancing:loadbalancer \
          --tag-filters "Key=elbv2.k8s.aws/cluster,Values=$cluster" \
          --query 'length(ResourceTagMappingList)' --output text)
  nodes=$(aws ec2 describe-instances --region "$region" \
          --filters "Name=tag:karpenter.sh/nodepool,Values=*" "Name=tag-key,Values=kubernetes.io/cluster/$cluster" \
                    "Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down" \
          --query 'length(Reservations[].Instances[])' --output text)
  echo "  load balancers: $lbs, karpenter instances: $nodes"
  if [ "$lbs" = "0" ] && [ "$nodes" = "0" ]; then break; fi
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "::error::Timed out waiting for controller-managed resources to be removed"; exit 1
  fi
  sleep 20
done

echo "Deleting leftover Load Balancer Controller security groups..."
for sg in $(aws ec2 describe-security-groups --region "$region" \
              --filters "Name=tag:elbv2.k8s.aws/cluster,Values=$cluster" \
              --query 'SecurityGroups[].GroupId' --output text); do
  aws ec2 delete-security-group --group-id "$sg" --region "$region" || echo "  could not delete $sg (will be retried by VPC destroy)"
done
echo "Pre-destroy cleanup complete."
