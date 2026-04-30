#!/bin/bash

# colori
RED="\033[0;31m"
LIME="\033[1;92m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"

BRED="\033[1;31m"
BCYAN="\033[1;36m"

RESET="\033[0m"

# inizializzazione variabili (globali)
process_active=0
process_r=0
process_s=0
process_i=0
process_z=0
process_d=0
process_t=0

# check parametri
check_arg () {
	if [ "$1" -ne 0 ]; then
		echo -e "${BRED}ERRORE: non servono argomenti${RESET}"
		exit 1
	fi
}

# conteggio dei processi
process_count () {
	process_active=$(ps -e --no-headers | wc -l)
	echo -e "${BCYAN}Processi attivi sono: $process_active${RESET}"
}

# controllo dello stato di un processo
check_status() {
	local pid=$1
	local status=$2

	case "${status:0:1}" in
		R) echo -e "processo $pid ---> ${LIME}in esecuzione${RESET}"
			((process_r++));;
		S) echo -e "processo $pid ---> ${RED}in attesa${RESET}"
			((process_s++));;
		I) echo -e "processo $pid ---> ${BLUE}inattivo${RESET}"
			((process_i++));;
		Z) echo -e "processo $pid ---> ${GREEN}zombie${RESET}"
			((process_z++));;
		D) echo -e "processo $pid ---> ${YELLOW}sleep non interrompibile${RESET}"
			((process_d));;
		T) echo -e "processo $pid ---> ${MAGENTA}stoppato${RESET}"
			((process_t++));;
		*) echo -e "processo $pid ---> ${BRED}stato sconosciuto${RESET}"
	esac
}

# stampa dei processi trovati
print_process () {
        echo -e "${LIME}Processi in esecuzione sono: $process_r${RESET}"
	echo -e "${RED}Processi in attesa sono: $process_s${RESET}"
	echo -e "${BLUE}Processi inattivi sono: $process_i${RESET}"
	echo -e "${GREEN}Processi zombie sono: $process_z${RESET}"
	echo -e "${YELLOW}Processi sleep non interrompibile sono: $process_d${RESET}"
	echo -e "${MAGENTA}Processi stoppato sono: $process_t${RESET}"
}

# funzione main
check_arg "$#"
while read -r pid status ; do
	check_status $pid $status
done < <(ps -eo pid,stat --no-headers)
process_count
print_process
