# Node or tools host disk full

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
df -h at 100%, NodeDiskFilling alert, kubelet DiskPressure, 'no space left on device'.

## Impact
Evictions, image pulls fail, Jenkins/Elasticsearch stop.

## Investigate (commands)
```bash
df -h; df -i
sudo du -xh --max-depth=1 /var | sort -h | tail
sudo crictl images | wc -l
sudo lsof +L1   # deleted files still held open
```

## Mitigate / Fix
sudo crictl rmi --prune; journalctl --vacuum-size=200M; docker system prune -af (tools host). Expand the EBS volume only if usage is legitimate.

## Prevention
Image GC thresholds, log retention (7d ES, 14d CloudWatch), predict_linear alert.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
