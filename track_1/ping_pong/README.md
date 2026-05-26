# Ping Pong

## Obiettivo
Simulare la migrazione di un container Docker tra due VM Vagrant.  
Il container `ealen/echo-server` si sposta ogni 60 secondi da un nodo all'altro, come una partita di ping pong.

---

# Struttura del progetto

```text
ping_pong/
├── Vagrantfile
├── provision.sh
└── coordinator.sh
```

- `Vagrantfile` → definisce le due macchine virtuali
- `provision.sh` → installa Docker automaticamente
- `coordinator.sh` → gestisce la “migrazione” del container tra le VM

---

# Vagrantfile

Il file `Vagrantfile` crea due VM chiamate `ping` e `pong`.

## Definizione della VM ping

```ruby
config.vm.define "ping" do |ping|
  ping.vm.hostname = "ping"
  ping.vm.network "forwarded_port", guest: 8080, host: 8080
end
```

### Spiegazione

- `config.vm.define "ping"`  
  crea una macchina virtuale chiamata `ping`

- `ping.vm.hostname = "ping"`  
  imposta il nome host interno della VM

- `forwarded_port`  
  collega la porta della VM alla porta del computer host:
  
  - porta `8080` della VM
  - → porta `8080` del Mac/PC

In questo modo il servizio Docker sarà raggiungibile da browser tramite:

```text
http://localhost:8080
```

---

## Configurazione risorse VM

```ruby
ping.vm.provider "virtualbox" do |vb|
  vb.name = "ping"
  vb.memory = "1024"
  vb.cpus = 1
end
```

### Spiegazione

Questa parte configura VirtualBox:

- `vb.name` → nome visualizzato in VirtualBox
- `vb.memory` → 1 GB di RAM
- `vb.cpus` → 1 CPU assegnata alla VM

---

## Provisioning automatico

```ruby
ping.vm.provision "shell", path: "provision.sh"
```

### Spiegazione

Quando viene eseguito:

```bash
vagrant up
```

Vagrant lancia automaticamente lo script `provision.sh` dentro la VM.

---

# provision.sh

Questo script installa Docker automaticamente sulle VM.

## Aggiornamento pacchetti

```bash
apt-get update
```

### Spiegazione

Aggiorna la lista dei pacchetti disponibili su Ubuntu.

---

## Installazione Docker

```bash
apt-get install -y docker.io
```

### Spiegazione

Installa Docker senza chiedere conferme (`-y`).

---

## Avvio servizio Docker

```bash
systemctl start docker
systemctl enable docker
```

### Spiegazione

- `start docker` → avvia Docker subito
- `enable docker` → fa partire Docker automaticamente al boot

---

## Permessi utente

```bash
usermod -aG docker vagrant
```

### Spiegazione

Aggiunge l'utente `vagrant` al gruppo Docker, così può usare Docker senza `sudo`.

---

## Messaggio finale

```bash
echo "$(hostname)'s VM pronta!"
```

### Spiegazione

- `hostname` stampa il nome della VM corrente
- `echo` mostra un messaggio finale

Esempio output:

```text
ping's VM pronta!
```

---

# coordinator.sh

Questo script coordina lo spostamento del container tra le VM.

---

# Verifica delle VM

```bash
check_nodes() {
  vagrant ssh ping -c "echo okey" &>/dev/null
}
```

### Spiegazione

Il comando:

```bash
vagrant ssh ping -c "echo okey"
```

esegue il comando `echo okey` dentro la VM `ping`.

Se la VM non è raggiungibile, il comando fallisce.

---

## Controllo errori

```bash
if (( $? != 0 )); then
  echo "Errore: VM ping non raggiungibile"
  exit 1
fi
```

### Spiegazione

- `$?` contiene il codice di uscita dell’ultimo comando
- `0` = successo
- valore diverso da `0` = errore

Se la VM non risponde, lo script termina con `exit 1`.

---

# Migrazione del container

## Avvio container su ping

```bash
echo "[$(date '+%H:%M:%S')] Migrazione container su PING"

vagrant ssh ping -c \
"docker run -d --name ping -p 8080:80 ealen/echo-server" \
&>/dev/null
```

### Spiegazione

Questo blocco:

1. stampa l’orario corrente
2. entra nella VM `ping`
3. avvia un container Docker

---

## Analisi del comando Docker

```bash
docker run -d --name ping -p 8080:80 ealen/echo-server
```

### Spiegazione dettagliata

- `docker run` → crea e avvia un container
- `-d` → modalità detached (in background)
- `--name ping` → assegna nome `ping`
- `-p 8080:80`
  - porta `80` del container
  - esposta sulla porta `8080` della VM
- `ealen/echo-server`
  → immagine Docker utilizzata

---

## Attesa di 60 secondi

```bash
sleep 60
```

### Spiegazione

Lo script aspetta 60 secondi prima di effettuare la migrazione successiva.

---

## Stop e rimozione container

```bash
vagrant ssh ping -c \
"docker stop ping && docker rm ping"
```

### Spiegazione

- `docker stop ping` → ferma il container
- `docker rm ping` → elimina il container

Il simbolo `&&` esegue il secondo comando solo se il primo va a buon fine.

---

# Migrazione su pong

La stessa logica viene ripetuta sulla VM `pong`.

```bash
vagrant ssh pong -c \
"docker run -d --name pong -p 8080:80 ealen/echo-server"
```

Il container sarà raggiungibile su:

```text
http://localhost:8081
```

perché nel `Vagrantfile` la VM `pong` espone la porta host `8081`.

---

# Loop infinito

```bash
while true; do
  ...
done
```

### Spiegazione

Il ciclo continua all’infinito:

1. container su `ping`
2. attesa
3. stop
4. container su `pong`
5. attesa
6. stop
7. ripeti

---

# Avvio del progetto

## Creazione delle VM

```bash
vagrant up
```

### Spiegazione

Crea e avvia automaticamente entrambe le VM.

---

## Avvio coordinatore

```bash
bash coordinator.sh
```

### Spiegazione

Avvia il sistema di migrazione automatica del container.

---

# Test dal browser

## Container attivo su ping

```text
http://localhost:8080
```

## Container attivo su pong

```text
http://localhost:8081
```

Aprendo gli URL nel browser si può verificare su quale VM il container è attualmente in esecuzione.