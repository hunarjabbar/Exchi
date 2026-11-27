#!/usr/bin/env bash
set -euo pipefail
repo=hunarjabbar/Exchi
[[ "${EXCHI_PROTECTION_APPROVED:-NO}" == YES ]] || { echo 'Explicit approval required'; exit 2; }
# Never replace an existing protection policy automatically.
for branch in main staging; do
  protected=$(gh api "repos/$repo/branches/$branch" --jq .protected)
  [[ "$protected" == false ]] || { echo "$branch already protected; inspect and update manually" >&2; exit 2; }
done
for branch in main staging; do
  gh api --method PUT "repos/$repo/branches/$branch/protection" --input - <<'JSON'
{"required_status_checks":{"strict":true,"contexts":["source-contracts","step-ab-runtime"]},"enforce_admins":true,"required_pull_request_reviews":{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1,"require_last_push_approval":true},"restrictions":null,"required_conversation_resolution":true,"allow_force_pushes":false,"allow_deletions":false}
JSON
  gh api "repos/$repo/branches/$branch" --jq '{name,protected}'
done
