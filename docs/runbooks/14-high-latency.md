# High latency / latency SLO breach

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
BankingLatencySLOBreach; p95 above 300 ms; users report slowness.

## Impact
Slow transfers, timeouts, retries (which raise load further).

## Investigate (commands)
```bash
Grafana: latency p95 by service, DB pool pending, node CPU
kubectl -n banking top pods; kubectl top nodes
psql -c "select * from pg_stat_activity where state='active' order by query_start;"
```

## Mitigate / Fix
Scale out the hot service (raise HPA min), kill slow/blocking queries, check CPU throttling or noisy neighbour on the node. If caused by a release, roll back via Git revert.

## Prevention
Load test before peak days, connection pool sizing, timeouts at every layer.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
