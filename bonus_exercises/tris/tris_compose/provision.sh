#!/bin/bash

#Installazione Docker + Docker Compose
apt-get update
apt-get install -y docker.io docker-compose-v2
systemctl start docker
systemctl enable docker
usermod -aG docker vagrant

#Creazione cartelle e file status.txt per ogni container
BASE_PATH="/home/vagrant/tris"
CELLS=(A1 A2 A3 B1 B2 B3 C1 C2 C3)

for CELL in "${CELLS[@]}"; do
    mkdir -p "$BASE_PATH/$CELL"
    echo "EMPTY" > "$BASE_PATH/$CELL/status.txt"
done

#Avvio dei 9 container

cd "$BASE_PATH"

#Forza la rimozione di eventuali container esistenti e ricrea i container
docker compose down --remove-orphans 2>/dev/null
docker compose up -d

echo "Container creati con Docker Compose!!!"