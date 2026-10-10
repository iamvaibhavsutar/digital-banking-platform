#!/bin/bash
# Kubernetes node prep (control plane and workers). Runs once via EC2 user_data. __ROLE__ is replaced by Terraform.
set -euxo pipefail
exec > >(tee /var/log/node-prep.log) 2>&1
export DEBIAN_FRONTEND=noninteractive
K8S_MINOR="v1.31"
ECR_PROVIDER_VERSION="v1.31.0"   # VERIFY: cloud-provider-aws release matching your Kubernetes minor


swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
cat > /etc/modules-load.d/k8s.conf <<EOT
overlay
br_netfilter
EOT
modprobe overlay; modprobe br_netfilter
cat > /etc/sysctl.d/99-k8s.conf <<EOT
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOT
sysctl --system

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg containerd unzip jq

# containerd with systemd cgroups
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd && systemctl restart containerd

# kubeadm / kubelet / kubectl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ECR credential provider: kubeadm nodes cannot pull from ECR without it (the permanent fix, not a pull secret)
curl -fsSL -o /usr/local/bin/ecr-credential-provider \
  "https://artifacts.k8s.io/binaries/cloud-provider-aws/${ECR_PROVIDER_VERSION}/linux/amd64/ecr-credential-provider-linux-amd64"
chmod +x /usr/local/bin/ecr-credential-provider
cat > /etc/kubernetes-credential-provider.yaml <<EOT
apiVersion: kubelet.config.k8s.io/v1
kind: CredentialProviderConfig
providers:
  - name: ecr-credential-provider
    matchImages:
      - "*.dkr.ecr.*.amazonaws.com"
    defaultCacheDuration: "12h"
    apiVersion: credentialprovider.kubelet.k8s.io/v1
EOT
cat > /etc/default/kubelet <<EOT
KUBELET_EXTRA_ARGS=--image-credential-provider-config=/etc/kubernetes-credential-provider.yaml --image-credential-provider-bin-dir=/usr/local/bin --system-reserved=cpu=100m,memory=300Mi --kube-reserved=cpu=100m,memory=300Mi --eviction-hard=memory.available<200Mi
EOT
systemctl enable kubelet

# SSM agent (Ubuntu AMIs ship it as a snap)
snap list amazon-ssm-agent >/dev/null 2>&1 || snap install amazon-ssm-agent --classic
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

# Role marker for humans/scripts
echo "__ROLE__" > /etc/node-role
echo "node-prep done for role __ROLE__"
