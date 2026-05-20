# Script Bash – Manipolazione Array

Questo progetto contiene due script Bash che elaborano gli argomenti passati da riga di comando applicando:

* conversione in maiuscolo
* ordinamento
* rimozione dei duplicati

---

## Esercizio 1 – Uso di pipe e comandi di sistema

### Obiettivo

Utilizzare comandi di sistema concatenati tramite pipe per trasformare i dati.

---

### Comandi principali

* while

```bash
while [ $i -le $# ]; do
```

Itera sugli argomenti passati allo script.

* espansione indiretta

```bash
${!i}
```

Permette l’accesso dinamico agli argomenti ($1, $2, ...).

* array

```bash
ARRAY[...]
```

Struttura dati per memorizzare gli argomenti.

* stampa

```bash
printf "%s\n" "${ARRAY[@]}"
```

Stampa ogni elemento dell’array su una riga.

* pipe

```bash
|
```

Collega l’output di un comando all’input del successivo.

* trasformazione maiuscole

```bash
tr '[:lower:]' '[:upper:]'
```

Converte i caratteri da minuscolo a maiuscolo.

* ordinamento e deduplicazione

```bash
sort -u
```

Ordina i valori e rimuove i duplicati.

---

## Esercizio 2 – Implementazione manuale

### Obiettivo

Riprodurre lo stesso comportamento senza utilizzare comandi esterni, ma solo costrutti Bash.

---

### Comandi e costrutti principali

* ciclo while

```bash
while [ condizione ]; do
```

Utilizzato per il popolamento dell’array e l’ordinamento.

* lunghezza array

```bash
${#ARRAY[@]}
```

Restituisce la lunghezza dell’array.

* confronto stringhe

```bash
[[ "${ARRAY[i]}" > "${ARRAY[i+1]}" ]]
```

Confronto lessicografico.

* variabile temporanea

```bash
TMP=...
```

Usata per lo scambio di valori.

* uppercase built-in

```bash
ARRAY[i]="${ARRAY[i]^^}"
```

Converte una stringa in maiuscolo.

* ciclo for con indice

```bash
for ((i=0; i<n; i++)); do
```

Iterazione sull’array.

* confronto duplicati

```bash
if [[ "${ARRAY[i]}" != "${ARRAY[i-1]}" ]]; then
```

Identifica elementi unici.

* append array

```bash
UNIQUE+=("${ARRAY[i]}")
```

Aggiunge elementi all’array dei valori unici.

* output

```bash
printf "%s\n" "${UNIQUE[@]}"
```

Stampa il risultato finale.

---

## Confronto

* Uso delle pipe:

  * più compatto
  * sfrutta strumenti già disponibili

* Implementazione manuale:

  * più dettagliata
  * utile per comprendere algoritmi e strutture dati

---

## Conclusione

I due approcci mostrano due modalità diverse di risolvere lo stesso problema:

* uno orientato all’uso degli strumenti di sistema
* uno focalizzato sulla logica e sul controllo esplicito del flusso

