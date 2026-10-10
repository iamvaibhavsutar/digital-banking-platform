# Logs stopped arriving in Kibana

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Kibana histogram flat since a point in time; apps healthy; Fluent Bit errors.

## Impact
No searchable logs for debugging or audit.

## Investigate (commands)
```bash
kubectl -n logging logs ds/fluent-bit --tail=30
nc -zv <tools-ip> 9200     # from a node: timeout = network, x509 = cert
curl --cacert /opt/elk/certs/ca/ca.crt -u elastic:... https://localhost:9200/_cat/indices/bank-logs-*?v   # on tools host
```

## Mitigate / Fix
Network: restore the tools SG rule (terraform apply). TLS: recreate es-ca Secret from /opt/elk/certs/ca/ca.crt and restart the DaemonSet. Fluent Bit replays from its saved offsets.

## Prevention
LogShipperErrors alert, SG rules in Terraform, ILM and disk alerts on the tools host.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
