# PersistentVolume / PVC problem

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Pod stuck ContainerCreating although PV/PVC are Bound; or PV Released after PVC delete.

## Impact
Stateful pod (in-cluster dev Postgres) will not start.

## Investigate (commands)
```bash
kubectl -n banking describe pod postgres-0 | tail
kubectl get pv,pvc -A
ls -la /data   # on the node holding the local volume
```

## Mitigate / Fix
Restore the missing host path, or clear a Released PV: kubectl patch pv <pv> -p '{"spec":{"claimRef":null}}'. Bound means claimed, not usable.

## Prevention
Use RDS / EBS-CSI for anything that matters; local volumes tie data to one disk.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
