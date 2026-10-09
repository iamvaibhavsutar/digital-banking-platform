#!/bin/bash
# Usage: ./scripts/smoke-test.sh [base-url]   (default: docker compose portal on :8080)
set -euo pipefail
BASE=${1:-http://localhost:8080}
echo "-- account lookup";  curl -fsS $BASE/api/accounts/ACC1001; echo
KEY=$(cat /proc/sys/kernel/random/uuid)
echo "-- transfer (key $KEY)"
for i in 1 2; do   # second call MUST return the same transaction and not debit twice
  curl -fsS -X POST $BASE/api/transfers -H 'Content-Type: application/json' -H "Idempotency-Key: $KEY" \
       -d '{"fromAccount":"ACC1001","toAccount":"ACC1002","amount":100.00}'; echo
done
echo "-- balances after (ACC1001 should drop by exactly 100.00)"
curl -fsS $BASE/api/accounts/ACC1001; echo; curl -fsS $BASE/api/accounts/ACC1002; echo
