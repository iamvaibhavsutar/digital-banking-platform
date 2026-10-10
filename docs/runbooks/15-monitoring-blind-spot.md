# Monitoring blind spot (targets missing)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Dashboards show 'No data' and nothing alerts; Prometheus Targets list has no banking targets.

## Impact
You are blind: SLO and target alerts cannot fire on missing data.

## Investigate (commands)
```bash
kubectl -n monitoring get servicemonitor banking-backends -o yaml
kubectl -n banking get svc --show-labels
# Prometheus UI > Status > Targets
```

## Mitigate / Fix
Fix the ServiceMonitor selector (tier: backend). BankingTargetsMissing (absent()) is the alert that catches this.

## Prevention
Alert on absence, monitor the monitor (CloudWatch ALB alarms live outside the cluster).

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
