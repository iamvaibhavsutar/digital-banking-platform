# Bad deploy: error-budget fast burn

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
BankingErrorBudgetFastBurn fires; 5xx jumps right after a deploy; Jenkins Verify stage red.

## Impact
Errors for the services in the new release; budget burns 14x faster than allowed.

## Investigate (commands)
```bash
# What changed?
git -C <gitops-repo> log --oneline -5
kubectl -n banking rollout history deploy/account-service
# Grafana: Banking - Golden Signals, find the step change
```

## Mitigate / Fix
MITIGATE FIRST: git revert the GitOps bump commit and push; Argo CD restores the previous tag in about a minute. Then revert the bad code on main of the app repo (otherwise the next commit redeploys it). Root cause afterwards.

## Prevention
Better smoke test, canary deploys (Argo Rollouts), SLO alerts watching every release.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
