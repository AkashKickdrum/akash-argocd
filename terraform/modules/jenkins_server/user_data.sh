#!/bin/bash
yum update -y

# Install Java 17
amazon-linux-extras enable corretto17
yum install -y java-17-amazon-corretto-devel

# Docker & Git
yum install -y docker git
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# Jenkins
wget -O /etc/yum.repos.d/jenkins.repo \
  https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum install -y jenkins
systemctl enable jenkins
systemctl start jenkins

# Wait Jenkins up & install plugins
sleep 30
jenkins-plugin-cli --plugins \
  sonar sonar-generic-coverage temurin-installer \
  dependency-check dependency-track
systemctl restart jenkins

# SonarQube container
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sh -s -- -b /usr/local/bin

# Done
