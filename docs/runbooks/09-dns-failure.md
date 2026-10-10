# DNS / CoreDNS failure

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
UnknownHostException, ArgoCD cannot resolve github.com, readiness flapping; delayed because of caching.

## Impact
Progressive: new connections fail as caches expire.

## Investigate (commands)
```bash
kubectl run dns-test -n default --rm -it --restart=Never --image=busybox:1.36 -- nslookup kubernetes.default
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n banking get networkpolicy
```

## Mitigate / Fix
CoreDNS down: kubectl -n kube-system scale deploy coredns --replicas=2. If default-namespace lookups work but banking fails, restore allow-dns-egress (ArgoCD selfHeal does this).

## Prevention
2 CoreDNS replicas with PDB, DNS egress policy in Git, alert on CoreDNS pods.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
