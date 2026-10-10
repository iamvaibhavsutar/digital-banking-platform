# Pod in CrashLoopBackOff

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Pod status CrashLoopBackOff, restarts increasing, BankingPodRestarting alert.

## Impact
New pods never become Ready; during a rollout old pods keep serving (maxUnavailable: 0).

## Investigate (commands)
```bash
kubectl -n banking get pods
kubectl -n banking describe pod <pod> | tail -20
kubectl -n banking logs <pod> --previous | tail -50
```

## Mitigate / Fix
Config/secret errors (wrong DB password, bad DB_URL): fix the source (Parameter Store / Git) then `kubectl -n banking rollout restart deploy/<svc>`. Bad image: `git revert` the GitOps bump commit.

## Prevention
Readiness-only DB checks (no restart storms), startup probes, smoke test after deploy, ExternalSecrets instead of hand-made Secrets.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
