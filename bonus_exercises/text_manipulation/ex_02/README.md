## Logica utilizzata nello script

Lo script ha l’obiettivo di analizzare il file `metriche.txt`, leggere tutte le misurazioni registrate e calcolare la media di utilizzo della CPU per ogni server presente.

Per rispettare i requisiti richiesti sono stati utilizzati:

* ciclo `while` con `read`
* array associativi
* ciclo `for`
* operazioni aritmetiche Bash

---

### 1. Creazione degli array associativi

All’inizio vengono creati due array associativi tramite il comando:

```bash
declare -A
```

Sono stati utilizzati due array:

```bash
declare -A cpu_totale
declare -A conteggio
```

Il primo array (`cpu_totale`) memorizza la somma totale dei valori CPU associati a ciascun server.

Esempio:

```text
cpu_totale["srv-web01"]=320
```

Il secondo array (`conteggio`) memorizza quante volte il server compare nel file.

Esempio:

```text
conteggio["srv-web01"]=6
```

---

### 2. Lettura del file con while e read

Il file viene letto riga per riga tramite:

```bash
while read server cpu
```

Ogni riga contiene due valori separati da spazio.

Esempio:

```text
srv-web01 54
```

Il comando `read` divide automaticamente i valori:

* `server` → nome del server
* `cpu` → valore CPU

La lettura continua fino alla fine del file grazie al reindirizzamento:

```bash
done < metriche.txt
```

---

### 3. Aggiornamento dei valori negli array

Per ogni riga letta viene aggiornata la somma CPU:

```bash
((cpu_totale[$server] += cpu))
```

Se ad esempio:

```text
srv-web01 54
srv-web01 40
```

l’array diventa:

```text
cpu_totale["srv-web01"]=94
```

Successivamente viene incrementato il numero di volte in cui compare il server:

```bash
((conteggio[$server]++))
```

Esempio:

```text
conteggio["srv-web01"]=2
```

---

### 4. Scorrimento dei server con ciclo for

Terminata la lettura del file, viene utilizzato un ciclo `for`:

```bash
for server in "${!cpu_totale[@]}"
```

`${!array[@]}` restituisce tutte le chiavi dell’array, cioè i nomi dei server.

Esempio:

```text
srv-web01
srv-db02
srv-auth01
srv-cache03
```

---

### 5. Calcolo della media

La media viene calcolata dividendo la somma totale CPU per il numero di occorrenze:

```bash
media=$(( cpu_totale[$server] / conteggio[$server] ))
```

Esempio:

```text
somma = 300
occorrenze = 5
media = 60
```

---

### 6. Output finale

Infine viene stampato il report:

```bash
echo "$server: $media%"
```

Output esempio:

```text
=== REPORT UTILIZZO MEDIO CPU ===
srv-web01: 54%
srv-db02: 48%
srv-auth01: 61%
srv-cache03: 50%
```

---

## Motivazione della scelta

È stato scelto l’utilizzo degli array associativi perché permettono di collegare direttamente ogni server ai suoi valori numerici, evitando cicli annidati o confronti ripetuti.

Questa soluzione risulta più efficiente, leggibile e facilmente scalabile nel caso in cui il numero di server aumenti.

```
```
