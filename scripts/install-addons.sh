#!/bin/bash
# Run on the tools host (or anywhere with kubectl+helm and the kubeconfig). Idempotent.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)

helm repo add traefik https://traefik.github.io/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add fluent https://fluent.github.io/helm-charts
helm repo add jetstack https://charts.jetstack.io
helm repo add external-secrets https://charts.external-secrets.io
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# metrics-server (HPA needs it; kubeadm kubelet certs are self-signed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' || true

# Ingress: Traefik on NodePort 30080 (the ALB target)
helm upgrade --install traefik traefik/traefik -n traefik --create-namespace -f "$REPO_ROOT/deploy/traefik-values.yaml"

# Monitoring
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  -f "$REPO_ROOT/deploy/monitoring/kube-prometheus-stack-values.yaml"
kubectl apply -f "$REPO_ROOT/deploy/monitoring/"

# Secrets + certificates
helm upgrade --install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --set installCRDs=true
helm upgrade --install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true

# Argo CD
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace
echo "Next: scripts/es-setup.sh, then logging (helm upgrade --install fluent-bit ...), then apply deploy/gitops/argocd/*.yaml"
