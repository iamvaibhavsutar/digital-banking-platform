# Container OOMKilled (exit 137)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Pod restarts with Last State: Terminated, Reason: OOMKilled, exit code 137.

## Impact
Requests fail while the pod restarts; repeated kills look like a crash loop.

## Investigate (commands)
```bash
kubectl -n banking describe pod <pod> | grep -A5 'Last State'
kubectl -n banking top pod
kubectl top node
```

## Mitigate / Fix
Raise the memory limit in values/<svc>.yaml via Git (never kubectl edit). Confirm JAVA_OPTS has -XX:MaxRAMPercentage=75. Look for leaks if usage climbs steadily.

## Prevention
Right-size requests/limits from real usage, alert on working-set vs limit, load test before peak days.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
