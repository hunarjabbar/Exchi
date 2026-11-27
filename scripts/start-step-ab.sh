#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; source .local-stepab.env; set +a
[[ "$AUTH_MODE" == dev && "$ALLOW_LOCAL_DEV_OTP" == YES && "$RUNTIME_DATABASE_URL" == postgresql://wholesale_stepab_login:*@127.0.0.1:55432/wholesale_test ]] || { echo 'Refusing non-local startup'; exit 2; }
mkdir -p .local-stepab-logs
pids=()
cleanup(){ for pid in "${pids[@]}"; do kill -- "-$pid" 2>/dev/null || true; done; }
trap cleanup EXIT; trap 'exit 130' INT; trap 'exit 143' TERM
# New process groups so Ctrl-C terminates each local npm/node tree. API receives no migration credentials.
setsid env -u DATABASE_URL -u WHOLESALE_LOCAL_DB_PASSWORD -u WHOLESALE_LOCAL_RUNTIME_PASSWORD RELEASE_ENV=local FINANCIAL_EXECUTION=LOCKED NODE_ENV=development npm run start -w @wholesale/enterprise-api > .local-stepab-logs/api.log 2>&1 & pids+=("$!")
apps=(public-web retailer-pwa distributor-portal field-sales-pwa driver-pwa command-centre)
for i in "${!apps[@]}"; do
 port=$((3000+i)); app=${apps[i]}
 setsid env -u DATABASE_URL -u RUNTIME_DATABASE_URL -u WHOLESALE_LOCAL_DB_PASSWORD -u WHOLESALE_LOCAL_RUNTIME_PASSWORD -u AUTH_OTP_HMAC_KEY -u AUTH_STAFF_TOTP_JSON -u AUTH_MODE -u AUTH_LIVE_APPROVED APP_ORIGIN="http://localhost:$port" ALLOW_DEV_OTP_PROXY=YES npm run start -w "@wholesale/$app" -- --hostname 127.0.0.1 > ".local-stepab-logs/$app.log" 2>&1 & pids+=("$!")
done
printf 'Local processes started; inspect .local-stepab-logs and run smoke tests from a second terminal. Ctrl-C stops these processes only.\n'
wait -n "${pids[@]}"; echo 'A local process stopped; check its log.'; exit 1
