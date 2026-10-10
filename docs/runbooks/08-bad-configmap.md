# Bad ConfigMap change (shared blast radius)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
ArgoCD Synced, pods running, no alert; new/restarted pods fail with UnknownHostException or wrong DB.

## Impact
Every backend that reads bank-config is affected at its next restart.

## Investigate (commands)
```bash
kubectl -n banking get cm bank-config -o yaml | grep DB_URL
git -C <gitops-repo> log -p -- base/20-config.yaml
```

## Mitigate / Fix
git revert the config commit, then kubectl -n banking rollout restart deploy/<each service>.

## Prevention
Checksum annotation to roll pods on config change, per-service ConfigMaps, config validation in CI.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
