# Tris Distribuito con Docker, Vagrant e Bash

## Introduzione

Questo progetto realizza una versione del gioco del tris utilizzando:
- Vagrant per creare una macchina virtuale Linux,
- Docker per gestire i container,
- Bash scripting per la logica di gioco.

L’obiettivo principale del progetto non è solamente creare il gioco, ma comprendere:
- il funzionamento dei container,
- il concetto di isolamento,
- l’utilizzo dei volumi Docker,
- la persistenza dello stato tramite filesystem,
- la comunicazione tra host, VM e container.

Ogni casella della griglia del tris viene rappresentata da un container Docker indipendente.

---

# Architettura del progetto

La griglia del tris è composta da 9 container:

```text
A1 A2 A3
B1 B2 B3
C1 C2 C3
```

Ogni container:
- rappresenta una casella,
- possiede un file `status.txt`,
- mantiene lo stato della casella:
  - `EMPTY`
  - `X`
  - `O`

La logica del gioco NON è distribuita nei container.

I container vengono utilizzati solamente come:
- unità isolate,
- contenitori di stato persistente.

---

# Struttura del progetto

```text
tris/
│
├── Vagrantfile
├── provision.sh
├── game.sh
│
├── A1/
│   └── status.txt
├── A2/
│   └── status.txt
├── A3/
│   └── status.txt
├── B1/
│   └── status.txt
├── B2/
│   └── status.txt
├── B3/
│   └── status.txt
├── C1/
│   └── status.txt
├── C2/
│   └── status.txt
└── C3/
    └── status.txt
```

---

# Configurazione della macchina virtuale

Il file `Vagrantfile` crea una VM Ubuntu con Docker installato automaticamente.

## Cartella condivisa

La direttiva:

```ruby
config.vm.synced_folder ".", "/home/vagrant/tris"
```

permette di condividere la cartella del progetto tra:
- host reale,
- macchina virtuale.

Questo consente di:
- modificare i file dal proprio editor locale,
- vedere immediatamente le modifiche nella VM,
- utilizzare i file come volumi Docker.

---

# Provisioning automatico

Il file `provision.sh` viene eseguito automaticamente da Vagrant al primo `vagrant up` e prepara l'ambiente completo.

## Installazione Docker
```bash
apt-get update
apt-get install -y docker.io
systemctl start docker
systemctl enable docker
usermod -aG docker vagrant
```
Installa Docker, avvia il servizio e aggiunge `vagrant` al gruppo `docker`.

## Creazione cartelle e file di stato
```bash
BASE_PATH="/home/vagrant/tris"
CELLS=(A1 A2 A3 B1 B2 B3 C1 C2 C3)

for CELL in "${CELLS[@]}"; do
    mkdir -p "$BASE_PATH/$CELL"
    echo "EMPTY" > "$BASE_PATH/$CELL/status.txt"
done
```
Per ogni casella crea una cartella dedicata e inizializza `status.txt` con il valore `EMPTY`.

## Avvio dei container
```bash
for CELL in "${CELLS[@]}"; do
    docker rm -f "$CELL" 2>/dev/null
    docker run -d --name "$CELL" \
        -v "$BASE_PATH/$CELL:/app" alpine \
        sleep infinity
done
```
Avvia 9 container Alpine, uno per casella, con la cartella montata come volume in `/app`.

---

# Utilizzo dei volumi Docker

Ogni container monta una cartella dedicata tramite:

```bash
-v "$BASE_PATH/$CELL:/app"
```

Esempio:

```text
Host/VM:
A1/status.txt
        ↓
Container:
 /app/status.txt
```

Questo permette:
- persistenza dello stato,
- condivisione filesystem,
- visualizzazione dello stato sia fuori che dentro il container.

---

# Logica del gioco

Il file `game.sh` contiene tutta la logica del tris.

Le principali funzionalità implementate sono:
- gestione turni,
- validazione input,
- scrittura mosse,
- visualizzazione griglia,
- controllo vittoria,
- controllo pareggio,
- reset partita.

---

# Gestione dell'azione

Ogni giocatore inserisce una casella:

```text
A1
B2
C3
```

La funzione `get_action()`:
- verifica che la casella esista,
- controlla che sia libera,
- salva la mossa.

```bash
STATUS=$(docker exec "$MOVE" cat /app/status.txt)
```

---

# Scrittura dello stato

La funzione `write_move()` aggiorna il file della casella:

```bash
docker exec "$MOVE" sh -c "echo X > /app/status.txt"
```

oppure:

```bash
docker exec "$MOVE" sh -c "echo O > /app/status.txt"
```

---

# Visualizzazione della griglia

La funzione `show_grid()` legge lo stato dei container:

```bash
VALUE=$(docker exec "$CELL" cat /app/status.txt)
```

e stampa la griglia:

```text
      1     2     3
A  |  X  |  .  |  O  |
B  |  .  |  X  |  .  |
C  |  O  |  .  |  X  |
```

---

# Controllo della vittoria

La funzione `check_win()` verifica:
- righe,
- colonne,
- diagonali.

```bash
"$A1$A2$A3"
"$A1$B2$C3"
"$A3$B2$C1"
```

Se una combinazione produce:
- `XXX`
- `OOO`

viene dichiarato il vincitore.

---

# Gestione del pareggio

La funzione `check_draw()` controlla se:
- tutte le caselle sono occupate,
- senza vincitori.

In questo caso la partita termina in pareggio.

---

# Reset del gioco

La funzione `reset_game()` reimposta tutte le caselle:

```bash
docker exec "$CELL" sh -c "echo EMPTY > /app/status.txt"
```

Questo permette di:
- riutilizzare gli stessi container,
- evitare la loro ricreazione.

---

# Gestione interruzione CTRL+C

Il progetto utilizza `trap` per intercettare `SIGINT`:

```bash
trap '...' SIGINT
```

In caso di interruzione:
- il gioco viene resettato,
- le caselle tornano vuote.

---

# Avvio del progetto

## 1. Avvio VM

```bash
vagrant up
```

---

## 2. Accesso alla VM

```bash
vagrant ssh
```

---

## 3. Entrare nella cartella progetto

```bash
cd /home/vagrant/tris
```

---

## 4. Rendere eseguibile lo script

```bash
chmod +x game.sh
```

---

## 5. Avviare il gioco

```bash
./game.sh
```
