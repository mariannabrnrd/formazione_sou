#!/bin/bash

ARRAY=()
i=1

while [ $i -le $# ]; do
	ARRAY[$((i-1))]="${!i}"
	((i++))
done

printf "%s\n" "${ARRAY[@]}" | tr '[:lower:]' '[:upper:]' | sort -u

#for index in "${ARRAY[@]}"; do
#	echo "$index"
#done
