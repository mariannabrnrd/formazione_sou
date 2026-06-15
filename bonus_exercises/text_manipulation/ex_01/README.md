# README.md

# Analisi File di Log in Bash

**Modulo: Manipolazione del Testo e Automazione in Bash**

## Obiettivo dell’esercizio

Nella directory principale è presente un file chiamato `accessi.txt`, contenente un indirizzo IP per ogni riga.

Lo scopo dell’esercizio è:

* analizzare il file `accessi.txt`
* individuare gli indirizzi IP duplicati
* contare quante volte compare ogni IP
* stampare a terminale i **3 indirizzi IP più frequenti**, ordinati dal più frequente al meno frequente

---

## Esempio di file input (`accessi.txt`)

```txt
192.168.1.10
10.0.0.5
192.168.1.10
172.16.0.2
1.2.3.4
192.168.1.10
10.0.0.5
8.8.8.8
1.2.3.4
```

---

## Output atteso

```txt
3 192.168.1.10
2 10.0.0.5
2 1.2.3.4
```

---

# Soluzione — Pipeline Unix

Comando utilizzato:

```bash
sort accessi.txt | uniq -c | sort -nr | head -3
```

Questo metodo sfrutta la filosofia Unix: concatenare più comandi semplici tramite **pipe (`|`)**.

---

## Analisi dettagliata del comando

## 1. `sort accessi.txt`

```bash
sort accessi.txt
```

Il comando `sort` ordina alfabeticamente tutte le righe del file.

Output intermedio:

```txt
1.2.3.4
1.2.3.4
10.0.0.5
10.0.0.5
172.16.0.2
192.168.1.10
192.168.1.10
192.168.1.10
8.8.8.8
```

### Perché è necessario?

Perché il comando `uniq` riesce a contare solo righe duplicate **adiacenti**.

---

## 2. Pipe `|`

```bash
|
```

La pipe prende l’output del comando precedente e lo passa direttamente al comando successivo senza creare file temporanei.

---

## 3. `uniq -c`

```bash
uniq -c
```

Il comando `uniq` elimina le ripetizioni consecutive.

L’opzione:

```bash
-c
```

significa **count**, cioè conta quante volte ogni riga compare.

Output:

```txt
2 1.2.3.4
2 10.0.0.5
1 172.16.0.2
3 192.168.1.10
1 8.8.8.8
```

---

## 4. `sort -nr`

```bash
sort -nr
```

Viene effettuato un secondo ordinamento.

Opzioni:

### `-n`

Ordina numericamente.

Senza `-n`, i numeri verrebbero confrontati come testo.

### `-r`

Ordine inverso (**reverse**).

Dal valore più alto al più basso.

Output:

```txt
3 192.168.1.10
2 10.0.0.5
2 1.2.3.4
1 172.16.0.2
1 8.8.8.8
```

---

## 5. `head -3`

```bash
head -3
```

Mostra soltanto le prime 3 righe.

Risultato finale:

```txt
3 192.168.1.10
2 10.0.0.5
2 1.2.3.4
```

---

## Flusso logico del comando

```text
Leggere file
      ↓
Ordinare IP
      ↓
Contare duplicati
      ↓
Riordinare per frequenza
      ↓
Prendere i primi 3 risultati
```

---

## Perché ho scelto questo approccio

Ho scelto questo metodo perché:

* semplice
* veloce
* sfrutta strumenti standard già presenti nel sistema
* richiede pochi comandi

Per esercizi di analisi log in Bash, questo approccio risulta generalmente il più lineare ed efficiente.

