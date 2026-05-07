#!/bin/bash

ARRAY=()
TMP=""
i=1

#popolo il mio array
while [ $i -le $# ]; do
        ARRAY[$((i-1))]="${!i}"
        ((i++))
done

n=${#ARRAY[@]}
i=0

#ordiniamo le stringhe nell'array (bubble sort brutto)
while [ $i -lt $((n-1)) ]; do
	if [[ "${ARRAY[i]}" > "${ARRAY[i+1]}" ]]; then
		TMP="${ARRAY[i]}"
		ARRAY[i]="${ARRAY[i+1]}"
		ARRAY[i+1]="${TMP}"
		i=0
	else
		((i++))
	fi
done

#trasformiamo in upper case
for ((i=0; i<n; i++)); do
	ARRAY[i]="${ARRAY[i]^^}"
done

UNIQUE=()
UNIQUE+=("${ARRAY[0]}")

#controlliamo i valori unici
for ((i=1; i<n; i++)); do
	if [[ "${ARRAY[i]}" != "${ARRAY[i-1]}" ]]; then
		UNIQUE+=("${ARRAY[i]}")
	fi
done

#stampo l'array
printf "%s\n" "${UNIQUE[@]}"
