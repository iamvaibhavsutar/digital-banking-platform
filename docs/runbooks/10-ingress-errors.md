# Ingress errors (404 / 502 / 503)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Customer sees 404/502/503 from the ALB or Traefik.

## Impact
Partial or total outage of the API entry point. The status code tells you the layer.

## Investigate (commands)
```bash
curl -i http://$ALB/api/accounts/ACC1001      # who answered?
aws elbv2 describe-target-health --target-group-arn <tg>
kubectl -n traefik get pods; kubectl -n banking get ingress,endpoints
kubectl -n banking get ingress account-service -o yaml | grep -A3 path
```

## Mitigate / Fix
ALB 503 = targets unhealthy (Traefik NodePort 30080/ping). Traefik 404 = no matching route (fix path in Git). Traefik 502/504 = backend not ready/slow. Revert the Git commit or helm values change.

## Prevention
ALB unhealthy-target alarm, ingress paths validated in CI, Traefik values in Git.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
