# Monitoraggio Processi in Bash

## Descrizione

Questo script Bash permette di analizzare i processi attivi su un sistema Linux, mostrando:

* Stato di ogni processo
* Conteggio totale dei processi
* Statistiche aggregate per stato

---

## Obiettivo dell'esercizio

* Contare i processi attivi
* Analizzare lo stato dei processi
* Utilizzare strutture di controllo (`if`, `case`)
* Implementare un ciclo `while`
* Gestire errori
* Utilizzare variabili e funzioni

---

## Utilizzo

### Esecuzione

```bash id="run001"
chmod +x script.sh
./script.sh
```

Lo script **non accetta argomenti**.

---

## Struttura dello script

### 1. Definizione dei colori

Vengono definite sequenze ANSI per colorare l'output:

```bash id="color001"
RED="\033[0;31m"
GREEN="\033[0;32m"
...
RESET="\033[0m"
```

---

### 2. Variabili globali

Servono per contare i processi per stato:

```bash id="var001"
process_r=0
process_s=0
process_i=0
process_z=0
process_d=0
process_t=0
```

---

### 3. Controllo argomenti

```bash id="arg001"
check_arg () {
	if [ "$1" -ne 0 ]; then
		echo -e "ERRORE: non servono argomenti"
		exit 1
	fi
}
```

Verifica che lo script venga eseguito senza parametri.

---

### 4. Lettura dei processi

```bash id="loop001"
while read -r pid status ; do
	check_status $pid $status
done < <(ps -eo pid,stat --no-headers)
```

* `ps -eo pid,stat` → recupera PID e stato dei processi
* Il ciclo `while` legge ogni riga e la analizza

---

### 5. Analisi dello stato

La funzione `check_status` usa un `case` per classificare i processi:

```bash id="case001"
case "${status:0:1}" in
```

### Stati principali:

* `R` → in esecuzione
* `S` → in attesa
* `I` → inattivo
* `Z` → zombie
* `D` → sleep non interrompibile
* `T` → stoppato

Ogni stato:

* viene stampato con un colore
* incrementa un contatore

---

### 6. Conteggio totale processi

```bash id="count001"
process_active=$(ps -e --no-headers | wc -l)
```

Conta il numero totale dei processi attivi.

---

### 7. Output finale

```bash id="out001"
print_process
```

Mostra un riepilogo dei processi per stato.

---

## Esempio di output

```text id="example001"
processo 1234 ---> in esecuzione
processo 1235 ---> in attesa
...

Processi attivi sono: 120

Processi in esecuzione sono: 10
Processi in attesa sono: 80
Processi inattivi sono: 20
Processi zombie sono: 1
...
```

---

## Gestione errori

* Se vengono passati argomenti → errore e uscita
* Uso di `exit 1` per terminare lo script

---

## Concetti utilizzati

* Variabili globali
* Funzioni Bash
* Costrutto `case`
* Ciclo `while`
* Redirezione e process substitution
* Comando `ps`
* Gestione output colorato

---

## Note

* Lo script utilizza `echo -e` per interpretare i colori ANSI
* Funziona su sistemi Linux con Bash
* L'output dipende dallo stato reale dei processi del sistema

