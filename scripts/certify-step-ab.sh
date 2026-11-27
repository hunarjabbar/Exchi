#!/usr/bin/env bash
# Local-only acceptance. Never promotes or enables financial execution.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p acceptance-evidence
# Remove stale success markers/logs from earlier attempts, preserving unrelated files.
rm -f acceptance-evidence/{runtime-result.txt,readiness.json,lockfile-sha256.txt,bootstrap.log,prisma-diff.sql,schema-drift-result.json,http-smoke.log,browser-auth.log,browser-offline.log}
# Capture status, not secret-bearing environment or raw application logs.
git rev-parse HEAD > acceptance-evidence/commit.txt
git status --short > acceptance-evidence/git-status.txt
node scripts/check-lock.mjs
sha256sum package-lock.json > acceptance-evidence/lockfile-sha256.txt
# Refuse already-running application endpoints; do not accidentally certify unrelated processes.
python3 - <<'PYPORT'
import socket
for port in (*range(3000,3006),4000):
    with socket.socket() as s:
        if s.connect_ex(("127.0.0.1",port))==0:
            raise SystemExit(f"Refusing occupied application port {port}")
PYPORT
# Full SQL acceptance + isolated contention + builds are already part of bootstrap.
bash scripts/bootstrap-step-ab.sh 2>&1 | tee acceptance-evidence/bootstrap.log
cp .local-stepab-logs/prisma-diff.sql acceptance-evidence/prisma-diff.sql
cp .local-stepab-logs/schema-drift-result.json acceptance-evidence/schema-drift-result.json
set -a; source .local-stepab.env; set +a
bash scripts/start-step-ab.sh > .local-stepab-logs/supervisor.log 2>&1 &
supervisor=$!
cleanup(){ kill -TERM "$supervisor" 2>/dev/null || true; wait "$supervisor" 2>/dev/null || true; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
ready=0
for attempt in $(seq 1 120); do
  kill -0 "$supervisor" 2>/dev/null || { echo 'Application supervisor stopped before readiness'; exit 1; }
  if curl --noproxy '*' -fsS --max-time 2 http://127.0.0.1:4000/v1/ready > acceptance-evidence/readiness.json 2>/dev/null; then
    ready=1
    for port in {3000..3005}; do
      if ! curl --noproxy '*' -fsSL --max-time 5 "http://localhost:$port/" >/dev/null 2>&1; then ready=0; break; fi
    done
    [[ $ready == 1 ]] && break
  fi
  sleep 2
done
[[ $ready == 1 ]] || { echo 'Runtime readiness timed out'; exit 1; }
npm run test:step-ab:smoke 2>&1 | tee acceptance-evidence/http-smoke.log
npm run test:step-ab:browser 2>&1 | tee acceptance-evidence/browser-auth.log
PATH="$PWD/node_modules/.bin:$PATH" python3 tests/browser-offline.py 2>&1 | tee acceptance-evidence/browser-offline.log
printf 'PASS: local runtime acceptance commands completed; review schema drift, dependencies and evidence before Step C.\n' | tee acceptance-evidence/runtime-result.txt
