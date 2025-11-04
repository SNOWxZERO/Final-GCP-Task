#!/bin/bash
set -euxo pipefail

LOG=/var/log/instance-startup.log
exec > >(tee -a "$LOG") 2>&1
echo "===== Startup script begin: $(date) ====="

sleep 10
apt-get update -y

# Install Docker
apt-get install -y docker.io
systemctl enable docker
systemctl start docker

# Install Git and gettext-base (for envsubst)
apt-get install -y git gettext-base

# Install Google Cloud SDK if not already installed
if ! command -v gcloud &> /dev/null; then
  echo "Installing Google Cloud SDK..."
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list
  apt-get install -y apt-transport-https ca-certificates gnupg curl
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  apt-get update -y && apt-get install -y google-cloud-cli
fi

# Install kubectl and GKE auth plugin
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl and GKE auth plugin via apt..."
  apt-get install -y kubectl google-cloud-cli-gke-gcloud-auth-plugin
fi

# Ensure tools are available for all users
echo 'export PATH=$PATH:/usr/bin:/usr/local/bin:/google-cloud-sdk/bin' | tee -a /etc/profile.d/gcloud-path.sh
chmod +x /etc/profile.d/gcloud-path.sh

# Add SNOW to docker group
USER_NAME=$(ls /home | head -n1)
usermod -aG docker "$USER_NAME"

echo "===== Startup script end: $(date) ====="


