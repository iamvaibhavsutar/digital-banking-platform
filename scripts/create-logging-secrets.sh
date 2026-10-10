#!/bin/bash
# Usage: FLUENTBIT_PASSWORD=... ./create-logging-secrets.sh /path/to/ca.crt
set -euo pipefail
: "${FLUENTBIT_PASSWORD:?}"
CA=${1:-/opt/elk/certs/ca/ca.crt}
kubectl create ns logging --dry-run=client -o yaml | kubectl apply -f -
kubectl -n logging create secret generic es-ca --from-file=http_ca.crt="$CA" --dry-run=client -o yaml | kubectl apply -f -
kubectl -n logging create secret generic es-credentials --from-literal=password="$FLUENTBIT_PASSWORD" --dry-run=client -o yaml | kubectl apply -f -
kubectl label ns logging pod-security.kubernetes.io/enforce=privileged --overwrite   # Fluent Bit needs hostPath
