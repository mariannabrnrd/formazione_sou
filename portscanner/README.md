# Port Scanning Script con Netcat

## Descrizione

Questo script Bash (`portscanning.sh`) permette di effettuare una scansione di porte su un host target utilizzando il comando `nc` (Netcat).

L'obiettivo è verificare quali porte, in un intervallo specificato, risultano aperte o chiuse.

---

## Utilizzo

### Comando

```bash id="cmd001"
./portscanning.sh <indirizzo_ip> <porta_min> <porta_max>
```

### Esempio

```bash id="cmd002"
./portscanning.sh 192.168.1.10 20 100
```

---

## Script

```bash id="code001"
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
```

---

## Spiegazione dello script

### 1. Acquisizione degli argomenti

```bash id="exp001"
TARGET=$1
PORT_MIN=$2
PORT_MAX=$3
```

Lo script accetta:

* IP del target
* Porta minima
* Porta massima

---

### 2. Validazione degli input

#### Numero di argomenti

Controlla che siano inseriti esattamente 3 parametri:

```bash id="exp002"
if [ "$#" -ne 3 ]; then
```

#### Ordine delle porte

Verifica che la porta minima sia minore o uguale alla massima:

```bash id="exp003"
if [ $PORT_MIN -gt $PORT_MAX ]; then
```

#### Validità dell'host

Effettua un ping veloce per verificare che l'host sia raggiungibile:

```bash id="exp004"
ping -c 1 -w 1 "$TARGET"
```

#### Range delle porte

Controlla che le porte siano comprese tra 0 e 65535:

```bash id="exp005"
if [ "$PORT_MIN" -lt 0 ] || [ "$PORT_MIN" -gt 65535 ]; then
```

---

### 3. Logica di scansione

Il ciclo `while` scorre tutte le porte nel range specificato:

```bash id="exp006"
while [ $PORT_MIN -le $PORT_MAX ]
```

Per ogni porta:

1. Tenta una connessione con Netcat:

```bash id="exp007"
nc -v -w 1 "$TARGET" "$PORT_MIN"
```

2. Analizza l'exit status (`$?`):

* `0` → connessione riuscita → porta aperta
* diverso da `0` → connessione fallita → porta chiusa o host non raggiungibile

3. Incrementa la porta:

```bash id="exp008"
((PORT_MIN++))
```

---

## Note importanti

* Il timeout di 1 secondo (`-w 1`) rende la scansione veloce ma meno precisa su reti lente.
* L'output di `nc` viene silenziato (`> /dev/null 2>&1`) per mostrare solo i risultati.
* Lo script richiede che `netcat (nc)` sia installato sul sistema.

---

## Possibili miglioramenti

* Correggere la variabile `$PORT` (attualmente non definita) con `$PORT_MIN`
* Aggiungere output colorato (verde = aperta, rosso = chiusa)
* Supporto per scansione parallela per velocizzare il processo
* Logging su file

