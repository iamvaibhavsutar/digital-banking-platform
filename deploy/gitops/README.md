# digital-banking-gitops (separate Git repository)

Copy the contents of `deploy/gitops/` into its own repository. Argo CD watches it; Jenkins only edits `values/<service>.yaml` (`tag:`).

    argocd/   Argo CD Applications (app-of-apps): kubectl apply -f argocd/00-root.yaml
    base/     namespace (PSA restricted), RBAC, ConfigMap, NetworkPolicies, quota, ExternalSecrets
    chart/    one generic Helm chart for all six workloads
    values/   per-service values (image tag is the only line CI changes)

Rollback = `git revert` the bump commit. Never `helm rollback` (Argo CD would sync it back).
