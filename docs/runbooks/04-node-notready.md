# Node NotReady

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
kubectl get nodes shows NotReady; pods Pending/Unknown; NodeMemoryLow alert.

## Impact
Capacity drops; with one worker down the cluster may not fit all pods (t3 workers are small).

## Investigate (commands)
```bash
kubectl get nodes; kubectl describe node <n> | tail -30
aws ssm start-session --target <instance-id>
sudo systemctl status kubelet containerd; sudo journalctl -u kubelet -n 100
free -m; df -h; dmesg | grep -i oom
```

## Mitigate / Fix
Restart kubelet/containerd; free disk or memory; if the instance is impaired the EC2 status alarm auto-recovers it. Drain and replace if needed: kubectl drain <n> --ignore-daemonsets --delete-emptydir-data.

## Prevention
Kubelet reservations + eviction thresholds (node-prep.sh), PDBs, a third worker, disk alerts.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
