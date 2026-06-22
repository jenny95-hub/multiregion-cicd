#!/bin/bash

apt-get update -y
apt-get upgrade -y

apt-get install -y \
docker.io \
git \
curl \
wget \
unzip

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

#########################################
# Install AWS CLI
#########################################

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

./aws/install

#########################################
# Install Terraform
#########################################

wget https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip

unzip terraform_1.8.5_linux_amd64.zip

mv terraform /usr/local/bin/

#########################################
# Run Jenkins Container
#########################################

docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17