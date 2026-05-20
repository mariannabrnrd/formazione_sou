#!/bin/bash

TARGET=$1
PORT_MIN=$2
PORT_MAX=$3

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
RESET="\033[0m"

#check degli argomenti
if [ "$#" -ne 3 ]; then
	echo -e "${RED}ERRORE: scrivere ./portascanning.sh <indirizzo_ip> <porta_min> <porta_max>${RESET}"
	exit 1
fi

#check valori porte
if [ $PORT_MIN -gt $PORT_MAX ]; then
	echo -e "${RED}ERRORE: inserire prima <porta_min> e poi <porta_max>${RESET}"
	exit 1
fi

#check dell'indirizzo ip tramite comando ping
ping -c 1 -w 1 "$TARGET" > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo -e "${RED}ERRORE: indirizzo ip non valido!${RESET}"
	exit 1
fi

#check della porta minima
if [ "$PORT_MIN" -lt 0 ] || [ "$PORT_MIN" -gt 65535 ]; then
	echo -e "${RED}ERRORE: porta non valida!${RESET}"
	exit 1
fi

#check della porta massima
if [ "$PORT_MAX" -lt 0 ] || [ "$PORT_MAX" -gt 65535 ]; then
        echo -e "${RED}ERRORE: porta non valida!${RESET}"
        exit 1
fi

#ciclo per netcat
while [ $PORT_MIN -le $PORT_MAX ]
do
	echo -e "${BLUE}verifico la porta $PORT_MIN su $TARGET...${RESET}"
	nc -v -w 1 "$TARGET" "$PORT_MIN" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}RISULTATO: la porta $PORT è aperta!${RESET}"
	else
       		echo -e "${RED}RISULTATO: la porta $PORT è chiusa/host irraggiungibile.${RESET}"

	fi
	((PORT_MIN++))
done
