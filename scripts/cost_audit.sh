#!/bin/bash
export AWS_PROFILE=bank AWS_REGION=ap-south-1
echo "== running EC2 =";   aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceType]' --output text
echo "== EBS volumes (unattached = 'available') =="; aws ec2 describe-volumes --query 'Volumes[].[VolumeId,Size,State]' --output text
echo "== Elastic IPs ==";  aws ec2 describe-addresses --query 'Addresses[].[PublicIp,AssociationId]' --output text
echo "== NAT gateways ==";  aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId' --output text
echo "== load balancers =="; aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName' --output text
echo "== RDS ==";           aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]' --output text
echo "== EBS snapshots =="; aws ec2 describe-snapshots --owner-ids self --query 'length(Snapshots)'
echo "== ECR images ==";    for r in $(aws ecr describe-repositories --query 'repositories[].repositoryName' --output text); do echo -n "$r: "; aws ecr list-images --repository-name $r --query 'length(imageIds)'; done
