#!/bin/bash

TARGET=$1
PORT_MIN=$2
PORT_MAX=$3

#check degli argomenti
if [ "$#" -ne 3 ]; then
	echo "ERRORE: scrivere ./portascanning.sh <indirizzo_ip> <porta_min> <porta_max>"
	exit 1
fi

#check valori porte
if [ $PORT_MIN -gt $PORT_MAX ]; then
	echo "ERRORE: inserire prima <porta_min> e poi <porta_max>"
	exit 1
fi

#check dell'indirizzo ip tramite comando ping
ping -c 1 -w 1 "$TARGET" > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "ERRORE: indirizzo ip non valido!"
	exit 1
fi

#check della porta minima
if [ "$PORT_MIN" -lt 0 ] || [ "$PORT_MIN" -gt 65535 ]; then
	echo "ERRORE: porta non valida!"
	exit 1
fi

#check della porta massima
if [ "$PORT_MAX" -lt 0 ] || [ "$PORT_MAX" -gt 65535 ]; then
        echo "ERRORE: porta non valida!"
        exit 1
fi

#ciclo per netcat
while [ $PORT_MIN -le $PORT_MAX ]
do
	echo "verifico la porta $PORT_MIN su $TARGET..."
	nc -v -w 1 "$TARGET" "$PORT_MIN" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "RISULTATO: la porta $PORT è aperta!"
	else
       		echo "RISULTATO: la porta $PORT è chiusa/host irraggiungibile."

	fi
	((PORT_MIN++))
done
