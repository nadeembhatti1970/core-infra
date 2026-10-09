#!/usr/bin/env bash
# Wait for upstream project workflows running on the same commit to finish, so
# applies happen in dependency order (e.g. core-vpc before core-eks) when one
# merge touches several projects. Fails if the upstream run failed.
# Usage: wait_for_upstream.sh <workflow-file> [<workflow-file> ...]
# Requires: GH_TOKEN, GITHUB_REPOSITORY, GITHUB_SHA
set -euo pipefail
timeout_s=7200
deadline=$(( $(date +%s) + timeout_s ))

for wf in "$@"; do
  while :; do
    runs=$(gh api "repos/${GITHUB_REPOSITORY}/actions/workflows/${wf}/runs?head_sha=${GITHUB_SHA}&branch=main&per_page=20" \
             --jq '[.workflow_runs[] | select(.event != "pull_request")]')
    active=$(jq '[.[] | select(.status != "completed")] | length' <<<"$runs")
    if [ "$active" = "0" ]; then
      latest=$(jq -r 'sort_by(.created_at) | last | .conclusion // "none"' <<<"$runs")
      case "$latest" in
        success|none) echo "upstream ${wf}: ${latest}"; break ;;
        *) echo "::error::Upstream workflow ${wf} concluded '${latest}' for ${GITHUB_SHA}"; exit 1 ;;
      esac
    fi
    [ "$(date +%s)" -lt "$deadline" ] || { echo "::error::Timed out waiting for ${wf}"; exit 1; }
    echo "waiting for ${active} run(s) of ${wf}..."
    sleep 30
  done
done
