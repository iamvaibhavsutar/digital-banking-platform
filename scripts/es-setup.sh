#!/bin/bash
# Run on the tools host in /opt/elk. Creates certs, starts ES, sets users/roles/ILM.
# Usage: ES_PASSWORD=... KIBANA_PASSWORD=... FLUENTBIT_PASSWORD=... ./es-setup.sh
set -euo pipefail
: "${ES_PASSWORD:?}" "${KIBANA_PASSWORD:?}" "${FLUENTBIT_PASSWORD:?}"
cd /opt/elk
printf 'ES_PASSWORD=%s\nKIBANA_PASSWORD=%s\n' "$ES_PASSWORD" "$KIBANA_PASSWORD" > .env && chmod 600 .env

if [ ! -d certs ]; then
  mkdir -p certs/ca certs/es
  openssl genrsa -out certs/ca/ca.key 4096
  openssl req -x509 -new -key certs/ca/ca.key -days 825 -subj "/CN=bank-es-ca" -out certs/ca/ca.crt
  openssl genrsa -out certs/es/es.key 2048
  IP=$(hostname -I | awk '{print $1}')
  openssl req -new -key certs/es/es.key -subj "/CN=elasticsearch" -out certs/es/es.csr
  printf "subjectAltName=DNS:localhost,DNS:elasticsearch,IP:127.0.0.1,IP:%s\n" "$IP" > certs/es/san.ext
  openssl x509 -req -in certs/es/es.csr -CA certs/ca/ca.crt -CAkey certs/ca/ca.key -CAcreateserial -days 825 -extfile certs/es/san.ext -out certs/es/es.crt
  chmod -R a+r certs
fi
docker compose up -d elasticsearch
until curl -s --cacert certs/ca/ca.crt -u elastic:"$ES_PASSWORD" https://localhost:9200 >/dev/null; do sleep 5; done

es() { local path=$1; shift; curl -s --cacert /opt/elk/certs/ca/ca.crt -u elastic:"$ES_PASSWORD" -H 'Content-Type: application/json' "https://localhost:9200${path}" "$@"; echo; }
es "/_security/user/kibana_system/_password" -X POST -d "{\"password\":\"$KIBANA_PASSWORD\"}"
# Writer-only role for Fluent Bit (can create/index, cannot read or delete)
es "/_security/role/bank_log_writer" -X PUT -d '{"indices":[{"names":["bank-logs-*","bank-audit-*"],"privileges":["create_index","create","index","auto_configure"]}]}'
es "/_security/user/fluentbit" -X PUT -d "{\"password\":\"$FLUENTBIT_PASSWORD\",\"roles\":[\"bank_log_writer\"]}"
# 7-day retention (lab value)
es "/_ilm/policy/bank-logs-7d" -X PUT -d '{"policy":{"phases":{"hot":{"actions":{}},"delete":{"min_age":"7d","actions":{"delete":{}}}}}}'
es "/_index_template/bank-logs" -X PUT -d '{"index_patterns":["bank-logs-*"],"template":{"settings":{"number_of_shards":1,"number_of_replicas":0,"index.lifecycle.name":"bank-logs-7d"}}}'
es "/_index_template/bank-audit" -X PUT -d '{"index_patterns":["bank-audit-*"],"template":{"settings":{"number_of_shards":1,"number_of_replicas":0,"index.lifecycle.name":"bank-logs-7d"}}}'
docker compose up -d kibana
echo "ES ready. CA cert for Fluent Bit: /opt/elk/certs/ca/ca.crt  (create the k8s secret es-ca from it)"
