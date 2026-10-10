# Architecture

    Customer -> ALB (public subnet) -> Traefik NodePort 30080 -> Services (kubeadm, 2 AZs, private subnets) -> RDS PostgreSQL (db subnets, no internet route)
    GitHub -> Jenkins -> ECR -> GitOps repo -> Argo CD -> cluster
    Prometheus/Grafana/Alertmanager(->SNS) + Fluent Bit -> Elasticsearch/Kibana, CloudTrail -> CloudWatch alarms

Subnets: public 10.0.1/2.0, private 10.0.11/12.0, db 10.0.21/22.0. Pod CIDR 10.244.0.0/16, service CIDR 10.96.0.0/12.

Workloads: auth, account, transfer, transaction, notification, portal. Only account-service runs Flyway.
