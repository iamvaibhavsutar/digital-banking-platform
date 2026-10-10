#!/bin/bash
# Run on kube-cp (SSM session) AFTER node-prep finished (cat /var/log/node-prep.log).
set -euo pipefail
CP_IP=$(hostname -I | awk '{print $1}')
cat > /root/kubeadm-config.yaml <<EOT
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: stable-1.31
networking:
  podSubnet: 10.244.0.0/16
  serviceSubnet: 10.96.0.0/12
controlPlaneEndpoint: ${CP_IP}:6443
# Permanent home for API-server hardening so it survives 'kubeadm upgrade' (Sections 16.9 / 16.11):
# apiServer:
#   extraArgs:
#     - name: encryption-provider-config
#       value: /etc/kubernetes/enc/enc.yaml
#     - name: audit-policy-file
#       value: /etc/kubernetes/audit/policy.yaml
#     - name: audit-log-path
#       value: /var/log/kubernetes/audit/audit.log
#   extraVolumes:
#     - name: enc
#       hostPath: /etc/kubernetes/enc
#       mountPath: /etc/kubernetes/enc
#       readOnly: true
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///run/containerd/containerd.sock
EOT
kubeadm init --config /root/kubeadm-config.yaml --upload-certs | tee /root/kubeadm-init.log
mkdir -p $HOME/.kube && cp /etc/kubernetes/admin.conf $HOME/.kube/config

# Calico (enforces NetworkPolicy; Flannel does not)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/calico.yaml
echo "Join workers with:"; kubeadm token create --print-join-command
