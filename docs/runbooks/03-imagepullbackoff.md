# ImagePullBackOff / ErrImagePull (ECR)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
Pod stuck ErrImagePull; events say 'no basic auth credentials', 403, or 'not found'.

## Impact
Only NEW pulls fail; running pods are fine until a restart/scale-up (Lab 1).

## Investigate (commands)
```bash
kubectl -n banking describe pod <pod> | tail -10
sudo journalctl -u kubelet | grep -i -E 'credential|ecr' | tail   # on the node
aws iam list-attached-role-policies --role-name bank-dev-k8s-node
aws ecr describe-images --repository-name <svc> --image-ids imageTag=<tag>
```

## Mitigate / Fix
Missing policy: `terraform apply` restores AmazonEC2ContainerRegistryReadOnly. Missing credential provider on a node: re-run deploy/bootstrap/node-prep.sh sections. Wrong tag: revert the GitOps commit.

## Prevention
Credential provider baked into node bootstrap, IAM managed by Terraform, CloudTrail alarm on DetachRolePolicy.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
