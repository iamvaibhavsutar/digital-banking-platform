# Digital Banking Payment Platform (AWS DevOps / SRE portfolio project)

Banking-style payment platform: Spring Boot services, kubeadm Kubernetes on AWS, Terraform, GitOps (Jenkins + Argo CD), Prometheus/Grafana, EFK, runbooks.

## Layout
    services/   auth, account, transfer, transaction, notification (Spring Boot 3, Java 21)
    frontend/   portal (static HTML) + nginx config
    terraform/  backend/ (state bucket), modules/, environments/dev
    deploy/     gitops/ (Helm chart, values, base manifests, Argo apps), monitoring/, logging/, tools/, bootstrap/, iam/, security/, k8s/
    scripts/    kubeadm-init, install-addons, es-setup, lab-up, cost_audit, smoke-test ...
    docs/       runbooks (18), SLO, postmortem template, known gaps, architecture

## Run locally
    docker compose up -d --build && ./scripts/smoke-test.sh      # portal on http://localhost:8080

## Build order on AWS
1. `terraform/backend` (state bucket) -> `terraform/environments/dev` (`terraform init -backend-config="bucket=<bucket>"`, copy `terraform.tfvars.example`)
2. `scripts/create-ssm-params.sh`; start the tools stacks from `deploy/tools/*` on the tools host; `scripts/es-setup.sh`
3. `scripts/kubeadm-init.sh` on kube-cp, join workers, `scripts/install-addons.sh`
4. Push `deploy/gitops/` to its own repo, `kubectl apply -f argocd/00-root.yaml`, configure the Jenkins multibranch job

Everything here was written without being run against a live account: expect small version/label fixes.
