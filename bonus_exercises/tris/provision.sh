#!/bin/bash

#Installazione Docker
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker vagrant

#Creazione cartella per i volumi
BASE_PATH="/home/vagrant/tris"
CELLS=(A1 A2 A3 B1 B2 B3 C1 C2 C3)

for CELL in "${CELLS[@]}"; do
    mkdir -p "$BASE_PATH/$CELL"
    echo "EMPTY" > "$BASE_PATH/$CELL/status.txt"
done

#Avvio dei 9 container
for CELL in "${CELLS[@]}"; do

    #rimuove eventuali container esistenti con lo stesso nome
    docker rm -f "$CELL" 2>/dev/null
    docker run -d --name "$CELL" \
        -v "$BASE_PATH/$CELL:/app" alpine \
        sleep infinity
done

echo "container creati !!!"