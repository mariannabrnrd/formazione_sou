# README.md

# Gioco del Tris distribuito con Vagrant, Ansible e Podman

## Obiettivo del progetto

L’obiettivo di questo progetto è realizzare una versione del **gioco del Tris (Tic Tac Toe)** utilizzando tecnologie di virtualizzazione, provisioning automatico e containerizzazione.

L’infrastruttura è composta da:

* **Vagrant** → creazione automatizzata della macchina virtuale
* **Ansible** → provisioning e configurazione automatica dell’ambiente
* **Podman** → creazione e gestione dei container rootless
* **Bash scripting** → implementazione della logica di gioco

L’idea alla base del progetto è rappresentare ogni singola cella della griglia di gioco come un container indipendente.

Ogni container mantiene il proprio stato attraverso un file `status.txt`.

---

# Architettura del progetto

```text
Host Machine
      │
      │ Vagrant
      ▼
Ubuntu Virtual Machine
      │
      │ Ansible provisioning
      ▼
Installazione Podman
      │
      ▼
Pod tris-pod
│
├── Container A1
├── Container A2
├── Container A3
├── Container B1
├── Container B2
├── Container B3
├── Container C1
├── Container C2
└── Container C3
```

Ogni container rappresenta una casella della griglia.

---

# Tecnologie utilizzate

| Tecnologia         | Scopo                           |
| ------------------ | ------------------------------- |
| Vagrant            | Provisioning della VM           |
| VirtualBox         | Virtualizzazione                |
| Ubuntu Jammy 22.04 | Sistema operativo               |
| Ansible            | Automazione configurazione      |
| Podman             | Gestione container rootless     |
| Bash               | Implementazione logica di gioco |

---

# 1. Configurazione Vagrant

File: `Vagrantfile`

Il file Vagrant crea automaticamente una macchina virtuale Ubuntu.

Configurazione principale:

```ruby id="c1"
config.vm.box = "ubuntu/jammy64"
```

Utilizza una VM Ubuntu 22.04.

---

### Configurazione risorse macchina

```ruby id="c2"
vb.memory = "2048"
vb.cpus = 2
```

Assegna:

* 2 GB RAM
* 2 CPU virtuali

---

### Cartella condivisa

```ruby id="c3"
config.vm.synced_folder ".", "/home/vagrant/tris"
```

Sincronizza la cartella locale del progetto con la VM.

---

### Provisioning Ansible

```ruby id="c4"
config.vm.provision "ansible_local"
```

Vagrant esegue automaticamente Ansible all’avvio della macchina.

---

# 2. Inventory Ansible

File: `inventory.yml`

```yaml id="c5"
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_user: vagrant
```

L’inventory definisce che il playbook verrà eseguito localmente sulla macchina virtuale.

---

# 3. Provisioning Ansible

File: `playbook.yml`

Ansible prepara automaticamente l’ambiente.

---

## Installazione Podman

```yaml id="c6"
- name: Installa Podman
  apt:
    name: podman
    state: present
```

Installa Podman come runtime per i container.

---

## Creazione directory delle celle

```yaml id="c7"
cells:
  - A1
  - A2
  ...
  - C3
```

Per ogni cella viene creata una directory dedicata.

Esempio:

```text id="c8"
/home/vagrant/tris/A1
/home/vagrant/tris/A2
...
```

---

## Inizializzazione stato

Per ogni container viene creato un file:

```text id="c9"
status.txt
```

Contenuto iniziale:

```text id="c10"
EMPTY
```

Significa che la casella è libera.

---

## Abilitazione Podman rootless

```yaml id="c11"
loginctl enable-linger vagrant
```

Permette all’utente `vagrant` di mantenere attivi i container anche senza sessione aperta.

---

## Creazione Pod

```bash id="c12"
podman pod create --name tris-pod
```

Viene creato un pod chiamato:

```text id="c13"
tris-pod
```

Il pod contiene tutti i container del gioco.

---

## Creazione dei 9 container

```bash id="c14"
podman run -d \
--pod tris-pod \
--name A1 \
-v /path/A1:/app:Z \
alpine sleep infinity
```

Ogni container:

* rappresenta una casella
* monta una directory locale
* utilizza immagine Alpine Linux
* rimane attivo tramite `sleep infinity`

---

# 4. Implementazione del gioco Bash

File: `game.sh`

La logica di gioco viene gestita tramite Bash.

L’aspetto principale del progetto è la comunicazione con i container Podman.

---

# Comandi Podman utilizzati nel gioco

## Scrittura di una mossa

Quando un giocatore effettua una mossa:

```bash id="p1"
podman exec "$MOVE" sh -c "echo X > /app/status.txt"
```

oppure

```bash id="p2"
podman exec "$MOVE" sh -c "echo O > /app/status.txt"
```

Il comando:

```bash id="p3"
podman exec
```

esegue un comando dentro un container esistente.

In questo caso modifica il file:

```text id="p4"
/app/status.txt
```

---

## Lettura dello stato di una cella

Per verificare il contenuto di una casella:

```bash id="p5"
podman exec "$CELL" cat /app/status.txt
```

Questo permette di sapere se la cella contiene:

```text id="p6"
EMPTY
X
O
```

---

## Reset del gioco

Quando si ricomincia una partita:

```bash id="p7"
podman exec "$CELL" sh -c "echo EMPTY > /app/status.txt"
```

Tutte le celle vengono riportate allo stato iniziale.

---

## Controllo celle occupate

Prima di scrivere una mossa viene controllato:

```bash id="p8"
STATUS=$(podman exec "$MOVE" cat /app/status.txt)
```

Se la cella non è vuota:

```text id="p9"
EMPTY
```

la mossa viene rifiutata.

---

## Visualizzazione griglia

Per mostrare lo stato corrente:

```bash id="p10"
VALUE=$(podman exec "$CELL" cat /app/status.txt)
```

Il gioco legge ogni container e costruisce la griglia.

---

## Controllo integrità container

All’avvio del gioco viene verificato che tutti i container siano attivi.

```bash id="p11"
podman ps --format "{{.Names}}"
```

Mostra tutti i container attivi.

Successivamente viene controllato che siano presenti esattamente 9 container.

---

# Logica di funzionamento

Il ciclo di gioco segue questo flusso:

```text id="logic1"
Avvio VM con Vagrant
        ↓
Esecuzione playbook Ansible
        ↓
Installazione Podman
        ↓
Creazione Pod tris-pod
        ↓
Creazione 9 container
        ↓
Inizializzazione file status.txt
        ↓
Avvio script Bash
        ↓
Input giocatore
        ↓
Scrittura stato nel container
        ↓
Controllo vittoria o pareggio
        ↓
Reset o nuova partita
```

---

# Avvio del progetto

## Avvio macchina virtuale

```bash id="run1"
vagrant up
```

---

## Accesso alla VM

```bash id="run2"
vagrant ssh
```

---

## Avvio gioco

```bash id="run3"
./game.sh
```

---

# Struttura progetto

```text id="tree1"
project/
│
├── Vagrantfile
├── inventory.yml
├── playbook.yml
├── game.sh
│
├── A1/status.txt
├── A2/status.txt
├── A3/status.txt
├── B1/status.txt
├── B2/status.txt
├── B3/status.txt
├── C1/status.txt
├── C2/status.txt
└── C3/status.txt
```

---

# Considerazioni finali

Questo progetto mostra come combinare diverse tecnologie DevOps per costruire un’applicazione distribuita:

* **Vagrant** automatizza la creazione della macchina virtuale
* **Ansible** automatizza il provisioning
* **Podman** gestisce container rootless senza daemon
* **Bash** implementa la logica applicativa

L’aspetto più interessante del progetto è rappresentare lo stato del gioco tramite container indipendenti, trasformando ogni casella del Tris in una piccola unità isolata e persistente.
