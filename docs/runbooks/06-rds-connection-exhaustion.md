# RDS connection exhaustion / pool starvation

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Logs: 'Connection is not available, request timed out after 5000ms'; hikaricp_connections_pending > 0; readiness flapping while RDS looks healthy.

## Impact
Pods leave the Service; Traefik returns 503 though the database is up.

## Investigate (commands)
```bash
kubectl -n banking logs deploy/account-service | grep -i 'not available'
psql -h <rds-endpoint> -U bank -d bankdb -c "select pid,state,wait_event_type,now()-xact_start age,left(query,60) from pg_stat_activity where datname='bankdb' order by xact_start;"
psql ... -c "select pid, pg_blocking_pids(pid) from pg_stat_activity where cardinality(pg_blocking_pids(pid))>0;"
```

## Mitigate / Fix
Terminate the blocker: select pg_terminate_backend(<pid>). If pools are oversized lower DB_POOL_SIZE in bank-config via Git and restart. Rule: replicas x pool x services < max_connections.

## Prevention
ALTER ROLE bank SET lock_timeout='5s', idle_in_transaction_session_timeout='30s', statement_timeout='15s'; connection alarm in CloudWatch; pooler (RDS Proxy/PgBouncer) at scale.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
