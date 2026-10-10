#!/bin/bash
# Tools host prep (Jenkins / SonarQube / Elasticsearch+Kibana via Docker Compose). Runs once via user_data.
set -euxo pipefail
exec > >(tee /var/log/tools-prep.log) 2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg unzip jq git openjdk-17-jre-headless postgresql-client

# Docker CE
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable --now docker

# AWS CLI v2
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscli.zip
unzip -q /tmp/awscli.zip -d /tmp && /tmp/aws/install

# kubectl / helm / trivy
curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" && chmod +x /usr/local/bin/kubectl
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -fsSL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Elasticsearch needs this
echo 'vm.max_map_count=262144' > /etc/sysctl.d/99-es.conf && sysctl --system

# SSM agent
snap list amazon-ssm-agent >/dev/null 2>&1 || snap install amazon-ssm-agent --classic
systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true

mkdir -p /opt/jenkins /opt/sonar /opt/elk
echo "tools-prep done (copy deploy/tools/* to /opt/jenkins, /opt/sonar, /opt/elk and run docker compose up -d)"
