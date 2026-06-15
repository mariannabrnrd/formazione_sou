#!/bin/bash

# Creazione di due array associativi
# cpu_totale memorizza la somma totale della CPU per ogni server
# conteggio memorizza quante volte compare ogni server

declare -A cpu_totale
declare -A conteggio

# Lettura del file riga per riga
# read separa automaticamente i due valori nelle variabili

while read server cpu
do
    # Se il server compare per la prima volta viene inizializzato automaticamente

    # Somma del valore CPU
    ((cpu_totale[$server] += cpu))

    # Incremento del numero di occorrenze
    ((conteggio[$server]++))

done < metriche.txt


# Stampa finale del report

echo "=== REPORT UTILIZZO MEDIO CPU ==="

# Ciclo for per scorrere tutti i server presenti nell’array

for server in "${!cpu_totale[@]}"
do
    # Calcolo della media
    media=$(( cpu_totale[$server] / conteggio[$server] ))

    # Stampa risultato
    echo "$server: $media%"
done
