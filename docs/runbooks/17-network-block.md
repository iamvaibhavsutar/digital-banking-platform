# Connectivity blocked (SG / NACL / route / NAT)

**Severity guide:** SEV1 if customers cannot transfer money; SEV2 if degraded; SEV3 otherwise.

## Symptoms
'connect timed out' (not refused); works from one subnet but not another; SSM sessions drop.

## Impact
New connections fail; existing pooled ones may keep working for a while.

## Investigate (commands)
```bash
nc -zv -w3 <rds-endpoint> 5432   # timeout = dropped, refused = reachable but closed
# Console: VPC > Reachability Analyzer > create path (node -> RDS ENI, TCP 5432)
aws ec2 describe-network-acls --network-acl-ids <id> --query 'NetworkAcls[0].Entries'
aws ec2 describe-route-tables --route-table-ids <rt> --query 'RouteTables[0].Routes'
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=RevokeSecurityGroupIngress --max-results 3
```

## Mitigate / Fix
terraform plan shows the missing rule/route; terraform apply restores it. Fix from your laptop if SSM is gone (route/NAT).

## Prevention
sg_changes CloudTrail alarm, NAT recover alarm, VPC endpoints for SSM, runbook fallback via EC2 console.

## Evidence to capture for the postmortem
Timeline (UTC), dashboard screenshot, the exact error line, who changed what (git log / CloudTrail), time-to-detect, time-to-mitigate.
