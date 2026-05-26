#!/bin/bash

#Controlliamo che i nodi esistano e siano raggiungibili
check_nodes() {
    vagrant ssh ping -c "echo okey" &>/dev/null
    if (( $? != 0)); then
        echo "Errore: VM ping non raggiungibile"
        exit 1
    fi
    vagrant ssh pong -c "echo okey" &>/dev/null
    if (( $? != 0 )); then
        echo "Errore: VM pong non raggiungibile"
        exit 1
    fi

    echo "Entrambe le VM sono raggiungibili"
}

#Inizio dello script
check_nodes
while true; do

    #Avvio container su PING
    echo "[$(date '+%H:%M:%S')] Migrazione container su PING"
    vagrant ssh ping -c "docker run -d --name ping -p 8080:80 ealen/echo-server" &>/dev/null
    echo "[$(date '+%H:%M:%S')] Container attivo su PING -> http://localhost:8080"
    sleep 60

    #Stoppa e rimuove il container su PING
    vagrant ssh ping -c "docker stop ping && docker rm ping" &>/dev/null
    echo "[$(date '+%H:%M:%S')]" Container stoppato su PING

    #Avvio container su PONG
    echo "[$(date '+%H:%M:%S')] Migrazione container su PONG"
    vagrant ssh pong -c "docker run -d --name pong -p 8080:80 ealen/echo-server" &>/dev/null
    echo "[$(date '+%H:%M:%S')] Container attivo su PONG -> http://localhost:8081"
    sleep 60

    #Stoppa e rimuove il container su PONG
    vagrant ssh pong -c "docker stop pong && docker rm pong"
    echo "[$(date '+%H:%M:%S')] Container stoppato su PONG"
done