# Known gaps and the production remedy for each

| Gap in this lab | Production answer |
|---|---|
| Single control-plane node | 3 control planes in separate AZs behind an LB, or EKS |
| Single NAT instance | NAT Gateway per AZ |
| Single-AZ RDS in dev | Multi-AZ (`multi_az = true`) plus tested restores |
| One Elasticsearch node, 7-day retention | HA cluster or managed service; archive to S3 with Object Lock |
| Node IAM role reachable from pods outside `banking` | Per-pod identity (IRSA / EKS Pod Identity) |
| etcd encryption key on the control-plane host | KMS provider |
| No admission policy engine / image signing | Kyverno or Gatekeeper + cosign verification |
| Services share one database | Database per service + saga/outbox |
| Self-signed in-cluster CA | ACM / a real CA at the edge (modules/dns) |
| No WAF in front of the ALB | AWS WAF |
| Lab auth-service (HMAC token, demo users) | OIDC provider (Keycloak/Cognito), real user store, JWT with rotation |
| No tracing | OpenTelemetry + correlation IDs |
