#!/bin/bash
set -euo pipefail
export AWS_PROFILE=bank AWS_REGION=ap-south-1
aws rds start-db-instance --db-instance-identifier bank-dev-postgres >/dev/null || true
IDS=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=digital-banking" "Name=instance-state-name,Values=stopped" \
      --query 'Reservations[].Instances[].InstanceId' --output text)
[ -n "$IDS" ] && aws ec2 start-instances --instance-ids $IDS >/dev/null
aws ec2 wait instance-running --filters "Name=tag:Project,Values=digital-banking"
aws rds wait db-instance-available --db-instance-identifier bank-dev-postgres
echo "Up. Give Kubernetes about 2 minutes, then: kubectl get nodes"
