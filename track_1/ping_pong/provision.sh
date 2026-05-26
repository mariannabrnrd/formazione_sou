#!/bin/bash

#Installazione Docker
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker vagrant

echo "$(hostname)'s VM pronta!"