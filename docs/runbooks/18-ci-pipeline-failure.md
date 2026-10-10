# CI pipeline failure / vulnerable dependency

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Jenkins red: Trivy found HIGH/CRITICAL, tests failed, ECR rejected a tag, or Verify failed.

## Impact
Nothing is deployed (that is the design) or the GitOps commit is auto-reverted.

## Investigate (commands)
```bash
# Jenkins console output; then locally:
trivy fs --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed .
aws ecr describe-images --repository-name <svc> --query 'imageDetails[].imageTags'
```

## Mitigate / Fix
Vulnerability: upgrade the dependency; if no fix exists record a time-boxed .trivyignore entry with reason and expiry. Immutable-tag clash: rebuild (new build number). Verify failure: pipeline already reverted; revert the code too.

## Prevention
Shift-left scans on every branch, SBOMs, dependency update bot.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
