#!/usr/bin/env bash
# Render and validate/apply a folder of Kubernetes manifests.
#
# Only the variables named in K8S_SUBST_VARS are substituted (e.g.
# K8S_SUBST_VARS='${AMP_REMOTE_WRITE_ENDPOINT}'); every other ${...} is left for
# the workload itself (e.g. ${CLUSTER_NAME} expanded by the ADOT collector).
#
# Usage:
#   k8s_apply.sh <manifest-dir> validate                         # YAML syntax only, no cluster
#   k8s_apply.sh <manifest-dir> dryrun <cluster-name> <region>   # kubectl apply --dry-run=client (read-only access)
#   k8s_apply.sh <manifest-dir> apply  <cluster-name> <region>
set -euo pipefail
dir="${1:?manifest directory}"
action="${2:?validate|apply}"
rendered=$(mktemp -d)
trap 'rm -rf "$rendered"' EXIT

shopt -s nullglob
files=("$dir"/*.yaml "$dir"/*.yml)
[ ${#files[@]} -gt 0 ] || { echo "::error::No manifests in $dir"; exit 1; }

for f in "${files[@]}"; do
  if [ -n "${K8S_SUBST_VARS:-}" ]; then
    envsubst "$K8S_SUBST_VARS" < "$f" > "$rendered/$(basename "$f")"
  else
    cp "$f" "$rendered/"
  fi
done

case "$action" in
  validate)
    for f in "$rendered"/*; do
      yq eval-all 'true' "$f" >/dev/null
      echo "valid YAML: $(basename "$f")"
    done
    ;;
  dryrun)
    cluster="${3:?cluster name}"
    region="${4:?region}"
    aws eks update-kubeconfig --name "$cluster" --region "$region" >/dev/null
    # Client-side dry run: kubectl reads live objects to compute the change but
    # sends no writes, so read-only RBAC (AmazonEKSAdminViewPolicy) is sufficient.
    kubectl apply --dry-run=client -f "$rendered"
    ;;
  apply)
    cluster="${3:?cluster name}"
    region="${4:?region}"
    # Refuse to apply manifests with an unresolved substitution
    for var in $(echo "${K8S_SUBST_VARS:-}" | grep -oE '[A-Z0-9_]+'); do
      [ -n "${!var:-}" ] || { echo "::error::$var is empty; refusing to apply"; exit 1; }
    done
    aws eks update-kubeconfig --name "$cluster" --region "$region" >/dev/null
    kubectl apply -f "$rendered"
    ;;
  *)
    echo "unknown action: $action" >&2; exit 2 ;;
esac
