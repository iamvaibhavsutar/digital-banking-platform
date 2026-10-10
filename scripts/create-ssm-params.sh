#!/bin/bash
# Creates the auth secrets in Parameter Store (the DB password is created by Terraform).
set -euo pipefail
export AWS_PROFILE=${AWS_PROFILE:-bank} AWS_REGION=ap-south-1
aws ssm put-parameter --name /banking/bank-dev/auth/secret --type SecureString --overwrite \
  --value "$(head -c 48 /dev/urandom | base64 | tr -d '\n')" >/dev/null
aws ssm put-parameter --name /banking/bank-dev/auth/demo-password --type SecureString --overwrite \
  --value "${AUTH_DEMO_PASSWORD:-demo123}" >/dev/null
echo "created /banking/bank-dev/auth/{secret,demo-password}"
