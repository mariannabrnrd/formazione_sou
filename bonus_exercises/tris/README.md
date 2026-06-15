# README.md

# Progetto Tris — Evoluzione di un'applicazione containerizzata

## Introduzione

Questo repository raccoglie tre diverse implementazioni del classico gioco **Tris (Tic Tac Toe)** sviluppate come esercizi pratici per approfondire concetti di:

* Bash scripting
* Containerizzazione
* Orchestrazione di servizi
* Infrastructure as Code
* Automazione del provisioning

L’obiettivo del progetto non è semplicemente implementare il gioco, ma mostrare una progressiva evoluzione architetturale, passando da una gestione manuale dei container fino ad arrivare ad un ambiente completamente automatizzato tramite strumenti DevOps.

Ogni versione rappresenta uno step di complessità crescente.

---

# Evoluzione del progetto

Il progetto è stato sviluppato in tre versioni successive.

```text id="flow1"
tris_simple
     ↓
tris_compose
     ↓
tris_ansible_podman
```

Ogni implementazione mantiene la stessa logica di base:

* 9 celle di gioco
* ogni cella rappresentata da un container
* ogni container mantiene il proprio stato
* il gioco viene gestito tramite Bash script

Ciò che cambia è l’infrastruttura utilizzata.

---

# 1. tris_simple

Prima implementazione del progetto.

## Obiettivo

Creare il gioco del Tris utilizzando esclusivamente **Docker** e Bash scripting.

Ogni cella della griglia viene rappresentata da un container Docker indipendente.

Lo stato di ogni cella viene salvato all’interno di un file dedicato.

---

## Tecnologie utilizzate

* Bash
* Docker

---

## Architettura

```text id="simple1"
Host Machine
      │
      ▼
Docker Engine
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

---

## Obiettivo didattico

Comprendere:

* funzionamento base dei container
* gestione manuale di Docker
* comunicazione tra Bash script e container

---

# 2. tris_compose

Seconda evoluzione del progetto.

## Obiettivo

Automatizzare la gestione dell’infrastruttura utilizzando **Docker Compose**.

La logica di gioco rimane invariata, ma la gestione dei container viene delegata ad un file di configurazione centralizzato.

---

## Tecnologie utilizzate

* Bash
* Docker
* Docker Compose

---

## Architettura

```text id="compose1"
Host Machine
      │
      ▼
Docker Compose
      │
      ▼
Multi Container Application
│
├── Service A1
├── Service A2
├── Service A3
├── Service B1
├── Service B2
├── Service B3
├── Service C1
├── Service C2
└── Service C3
```

---

## Miglioramenti rispetto alla prima versione

Prima versione:

```bash id="cmp1"
docker run ...
docker run ...
docker run ...
```

Seconda versione:

```bash id="cmp2"
docker compose up
```

---

## Obiettivo didattico

Comprendere:

* concetto di multi-container application
* Infrastructure as Code base
* gestione centralizzata dei servizi

---

# 3. tris_ansible_podman

Terza implementazione e versione più avanzata del progetto.

## Obiettivo

Automatizzare completamente l’ambiente di esecuzione utilizzando:

* Vagrant
* Ansible
* Podman

In questa versione non si lavora più direttamente sull’host locale.

L’intera infrastruttura viene creata automaticamente.

---

## Tecnologie utilizzate

* Bash
* Vagrant
* VirtualBox
* Ubuntu
* Ansible
* Podman

---

## Architettura

```text id="adv1"
Host Machine
      │
      │ Vagrant
      ▼
Virtual Machine Ubuntu
      │
      │ Ansible provisioning
      ▼
Podman
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

---

## Caratteristiche principali

### Vagrant

Gestisce la creazione automatica della macchina virtuale.

```bash id="adv2"
vagrant up
```

---

### Ansible

Automatizza il provisioning.

* installazione Podman
* creazione cartelle
* configurazione ambiente

---

### Podman

Sostituisce Docker utilizzando container rootless.

```bash id="adv3"
podman run ...
```

---

### Pod

I container vengono raggruppati in un pod.

```bash id="adv4"
podman pod create --name tris-pod
```

---

## Obiettivo didattico

Comprendere:

* Infrastructure as Code avanzata
* provisioning automatico
* container management con Podman
* automazione DevOps

---

# Confronto tra le tre versioni

| Progetto            | Tecnologie                        | Livello    |
| ------------------- | --------------------------------- | ---------- |
| tris_simple         | Bash + Docker                     | Base       |
| tris_compose        | Bash + Docker Compose             | Intermedio |
| tris_ansible_podman | Bash + Vagrant + Ansible + Podman | Avanzato   |

---

# Progressione tecnica

Ogni versione introduce un nuovo livello di complessità.

```text id="progress1"
Docker manuale
      ↓
Docker Compose orchestration
      ↓
Virtual Machine provisioning
      ↓
Ansible automation
      ↓
Podman rootless containers
```

---

# Competenze sviluppate

Attraverso questi esercizi sono stati approfonditi diversi aspetti pratici.

### Bash scripting

* gestione input
* controllo di flusso
* array
* funzioni
* validazione

### Containerizzazione

* gestione container
* isolamento processi
* persistenza tramite volume

### Orchestrazione

* multi-container architecture
* service management

### DevOps Automation

* provisioning automatico
* Infrastructure as Code
* configurazione automatizzata

---

# Conclusione

Questo progetto rappresenta un percorso progressivo di apprendimento nel mondo DevOps.

Partendo da una semplice gestione manuale dei container, si arriva ad una soluzione più strutturata e automatizzata.

L’obiettivo non è solamente realizzare il gioco del Tris, ma utilizzare il progetto come caso pratico per imparare:

* containerization
* orchestration
* automation
* infrastructure provisioning
* DevOps workflow

Ogni versione mantiene la stessa logica applicativa, ma introduce strumenti sempre più avanzati per la gestione dell’infrastruttura.
