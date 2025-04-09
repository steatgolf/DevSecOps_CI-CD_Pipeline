#!/bin/bash

# Fail on error and undefined variables
set -euo pipefail

# Run script in non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# Update and upgrade the system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install awscli
sudo apt-get install unzip
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

# Add Docker's official GPG key:
sudo apt-get install -y --no-install-recommends ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker
sudo apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start docker service
sudo systemctl enable --now docker

#Run nginx for testing
# sudo docker run -d -p 80:80 nginx
