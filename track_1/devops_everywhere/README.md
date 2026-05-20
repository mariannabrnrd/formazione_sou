# README.md — Progetto Vagrant “System Dashboard”

## Descrizione del progetto

Questo progetto crea automaticamente una macchina virtuale Ubuntu tramite Vagrant e VirtualBox.  
Una volta avviata con `vagrant up`, la VM installa automaticamente un server web Apache e genera una dashboard HTML che mostra informazioni di sistema aggiornate ogni minuto.

L’obiettivo dell’esercizio era creare un progetto semplice, portabile e completamente automatico tramite provisioning.

---

# Struttura del progetto

- `Vagrantfile` → definisce la macchina virtuale
- `provision.sh` → configura automaticamente il sistema
- `update-dashboard.sh` → script generato automaticamente che aggiorna la pagina web

---

# Vagrantfile

```ruby
Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "system-dashboard"

  config.vm.network "private_network", ip: "192.168.33.10"
  
  config.vm.provider "virtualbox" do |vb|
    vb.name = "system-dashboard"
    vb.memory = "1024"
    vb.cpus = 1
  end

  config.vm.provision "shell", path: "provision.sh"
end
```

---

# Spiegazione del Vagrantfile

## 0 . il "contenitore" principale

```ruby
Vagrant.configure("2") do |config|
  ....
end
```

### cosa significa:

come abbiamo visto questo dice a vagrant:  
“usa le regole moderne (versione 2) per leggere quello che c'è scritto qui dentro. Da adesso in poi, ogni volta che scrivo config, mi riferisco alle opzioni di questa macchina virtuale”.

---

## 1 . il sistema operativo

```ruby
config.vm.box = "ubuntu/jammy64"
```

### cosa significa:

“Vagrant, come base per questo computer usa l'immagine di Ubuntu 22.04 LTS”.

È l'equivalente di scegliere quale sistema operativo installare da una chiavetta USB.

---

## 2 . il nome del computer

```ruby
config.vm.hostname = "system-dashboard"
```

### cosa significa:

questo imposta il nome interno del computer (hostname).  
quando accenderai quella macchina virtuale e aprirai il terminale, leggerai qualcosa tipo:

```bash
vagrant@system-dashboard
```

serve per riconoscerla.

---

## 3 . la rete privata (indirizzo IP)

```ruby
config.vm.network "private_network", ip: "192.168.33.10"
```

### cosa significa:

creiamo una rete privata tra il tuo PC reale e la macchina virtuale.  
le assegniamo l'indirizzo IP `192.168.33.10`.

in questo modo, digitando quell'IP nel browser del tuo PC, potrai “parlare” direttamente con la macchina virtuale.

---

## 4 . i muscoli della macchina (hardware)

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.name = "system-dashboard"
  vb.memory = "1024"
  vb.cpus = 1
end
```

### cosa significa:

qui stai parlando direttamente con VirtualBox e gli stiamo dicendo:

- `vb.name` → “su VirtualBox, dai a questa macchina il nome visibile ‘system-dashboard’”
- `vb.memory` → “assegna a questo computer 1024 MB di RAM (1GB)”
- `vb.cpus` → “usa solo un processore (CPU) del mio computer”

---

## 5 . il "maggiordomo" (la configurazione automatica)

```ruby
config.vm.provision "shell", path: "provision.sh"
```

### cosa significa:

questa è la parte più potente.

dice a Vagrant:

“appena il computer è acceso e pronto, prendi il file che si chiama `provision.sh` ed eseguilo automaticamente all'interno della macchina virtuale”.

---

# Provision.sh

è il “maggiordomo” che configura la macchina virtuale appena si accende.

questo script fa 3 cose:

- installa un server web
- crea un secondo mini-script che raccoglie i dati del computer
- fa in modo che questo mini-script venga eseguito automaticamente ogni minuto per tenere aggiornata la pagina web

---

# 1 . inizio e installazione del Server Web

```bash
#!/bin/bash
```

dice alla macchina:

“hey, questo è uno script bash, esegui i comandi che seguono nel terminale”.

---

```bash
apt-get update -y
apt-get install -y apache2
```

aggiorna la lista dei pacchetti disponibili e poi installa Apache2, che è il software che trasforma la macchina virtuale in un vero e proprio server web.

il `-y` serve a dire “sì” in automatico a tutte le domande durante l'installazione.

---

# 2 . creazione del secondo script

```bash
cat << 'SCRIPT' > /usr/local/bin/update-dashboard.sh
...
SCRIPT
```

questo comando (Heredoc) dice:

“prendi tutto quello che c'è scritto qui fino alla parola `SCRIPT` in fondo, e salvalo dentro un nuovo file chiamato `update-dashboard.sh`”.

in pratica, lo script principale sta creando un secondo script “figlio”.

---

```bash
HOSTNAME=$(hostname)
UPTIME=$(uptime -p)
RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
IP=$(hostname -I | awk '{print $2}')
DATETIME=$(date '+%d/%m/%Y %H:%M:%S')
DISTRO=$(lsb_release -d | awk -F'\t' '{print $2}')
```

queste righe di comando interrogano il computer e salvano le risposte in delle “variabili”:

- `HOSTNAME` = prende il nome del computer
- `UPTIME` = controlla da quanto tempo il computer è acceso, mostrandolo in un formato leggibile
- `RAM_TOTAL` = controlla lo stato della memoria e isola il dato della RAM totale disponibile
- `RAM_USED` = fa la stessa cosa del comando sopra, ma isola il dato della RAM attualmente utilizzata in quel momento
- `IP` = chiede al sistema tutti i suoi indirizzi di rete e isola il secondo indirizzo IP
- `DATETIME` = prende data e ora correnti
- `DISTRO` = interroga il sistema per sapere quale versione di Linux è installata e ripulisce il testo per mostrare solo il nome pulito

subito dopo queste variabili, vengono usate dentro la pagina HTML per mostrare i dati reali.

---

# 3 . Permessi ed esecuzione immediata

```bash
chmod +x /usr/local/bin/update-dashboard.sh
```

rende lo script “figlio” appena creato eseguibile.

senza questo comando, Linux lo vedrebbe come un semplice file di testo e si rifiuterebbe di avviarlo.

---

```bash
/usr/local/bin/update-dashboard.sh
```

lo esegue immediatamente per la prima volta, così la pagina web viene creata subito.

---

# 4 . Aggiornamenti automatici (il trucco della magia)

```bash
echo "* * * * * root /usr/local/bin/update-dashboard.sh" > /etc/cron.d/dashboard
```

questo comando usa il sistema `cron`.

i 5 `*` significano:

“ogni singolo minuto di ogni giorno”.

quindi si sta dicendo:

“ogni minuto, l'utente root deve avviare lo script `update-dashboard.sh`”.

grazie a questo i dati si aggiorneranno da soli sul sito web ogni 60 secondi.

---

# 5 . Avvio del server web

```bash
systemctl enable apache2
systemctl start apache2
```

dice al server web Apache di accendersi subito e fa in modo che si riaccenda automaticamente anche dopo un riavvio della macchina virtuale.

---

# Obiettivo del progetto

Questo progetto dimostra:

- utilizzo di Vagrant
- provisioning automatico tramite shell scripting
- configurazione automatica di un server Linux
- automazione tramite cron
- creazione dinamica di una dashboard web
