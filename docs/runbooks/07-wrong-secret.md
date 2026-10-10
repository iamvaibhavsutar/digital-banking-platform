# Wrong or rotated secret (time-delayed failure)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
New pods CrashLoop with auth errors while old pods keep serving; nothing failed at the moment of the change.

## Impact
Failure appears on the next restart/scale-up/drain, hours later.

## Investigate (commands)
```bash
kubectl -n banking logs <new-pod> --previous | grep -i password
kubectl -n banking get externalsecret
aws ssm get-parameter --name /banking/bank-dev/db/password --with-decryption --query Parameter.Value --output text
```

## Mitigate / Fix
Fix the value in Parameter Store, wait for ESO (or force: kubectl annotate externalsecret db-credentials force-sync=$(date +%s) --overwrite), then rollout restart. 'rollout undo' does NOT help: Secrets are not part of the Deployment revision.

## Prevention
External Secrets + Reloader, change log for every config change, never hand-create Secrets.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
