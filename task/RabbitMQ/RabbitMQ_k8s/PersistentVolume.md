# Persistenza dei Dati in RabbitMQ su Kubernetes
## PersistentVolume (PV) e PersistentVolumeClaim (PVC)

---

## Indice

1. [Il problema della persistenza nei container](#1-il-problema-della-persistenza-nei-container)
2. [Architettura dello storage in Kubernetes](#2-architettura-dello-storage-in-kubernetes)
3. [PersistentVolume (PV)](#3-persistentvolume-pv)
4. [PersistentVolumeClaim (PVC)](#4-persistentvolumeclaim-pvc)
5. [StorageClass e provisioning dinamico](#5-storageclass-e-provisioning-dinamico)
6. [Ciclo di vita di PV e PVC](#6-ciclo-di-vita-di-pv-e-pvc)
7. [Access Modes](#7-access-modes)
8. [Reclaim Policy](#8-reclaim-policy)
9. [Cosa contiene il volume di RabbitMQ](#9-cosa-contiene-il-volume-di-rabbitmq)
10. [PVC in RabbitMQ Cluster Operator](#10-pvc-in-rabbitmq-cluster-operator)
11. [Verifica dello stato dei volumi](#11-verifica-dello-stato-dei-volumi)
12. [Scenari di failure e resilienza](#12-scenari-di-failure-e-resilienza)

---

## 1. Il problema della persistenza nei container

I container, per design, sono **effimeri**: il loro filesystem è temporaneo e viene distrutto insieme al container stesso. In Kubernetes, ogni volta che un Pod viene riavviato, crashato o ricreato, tutto ciò che era scritto nel filesystem del container viene perso.

Questo comportamento è accettabile per applicazioni stateless (es. un server HTTP), ma è **incompatibile** con sistemi stateful come RabbitMQ, che devono mantenere:

- la topologia del cluster (quali nodi esistono e come sono collegati)
- utenti, permessi e vhost configurati
- messaggi persistenti in coda
- lo stato interno del consensus delle quorum queue

Kubernetes risolve questo problema attraverso il meccanismo dei **PersistentVolume**, che disaccoppia il ciclo di vita dello storage da quello del Pod.

---

## 2. Architettura dello storage in Kubernetes

Lo storage persistente in Kubernetes è composto da tre livelli:

```
┌─────────────────────────────────────────────────┐
│                     POD                         │
│  (monta il volume su /var/lib/rabbitmq/mnesia)  │
└──────────────────────┬──────────────────────────┘
                       │ riferimento a
┌──────────────────────▼──────────────────────────┐
│           PersistentVolumeClaim (PVC)           │
│         "voglio 10Gi di storage RWO"            │
└──────────────────────┬──────────────────────────┘
                       │ binding con
┌──────────────────────▼──────────────────────────┐
│            PersistentVolume (PV)                │
│       storage fisico allocato (Ceph RBD)        │
└──────────────────────┬──────────────────────────┘
                       │ gestito da
┌──────────────────────▼──────────────────────────┐
│              StorageClass                       │
│   (ceph-rbd / standard / local-path ...)        │
└─────────────────────────────────────────────────┘
```

Il principio fondamentale è il **disaccoppiamento**: il Pod non conosce i dettagli del backend di storage (Ceph, NFS, AWS EBS, ecc.). Interagisce esclusivamente con il PVC, che funge da astrazione. È la StorageClass a sapere come allocare fisicamente lo storage.

---

## 3. PersistentVolume (PV)

Un **PersistentVolume** è una risorsa del cluster che rappresenta un'unità di storage fisico già allocata o allocabile. Può essere:

- un volume Ceph RBD (come nel nostro caso)
- un disco AWS EBS / GCP PD / Azure Disk
- un volume NFS
- un path locale sul nodo (`local-path` usato da kind)

Il PV esiste **indipendentemente dai Pod** — il suo ciclo di vita è gestito dall'amministratore del cluster (o dalla StorageClass tramite provisioning dinamico).

### Esempio di PersistentVolume (creato automaticamente da Ceph)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pvc-10be787b-f96b-4dc2-999d-096d14ffa07c
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: ceph-rbd
  csi:
    driver: rbd.csi.ceph.com
    volumeHandle: pvc-10be787b-f96b-4dc2-999d-096d14ffa07c
```

### Stati di un PV

| Stato | Significato |
|-------|-------------|
| `Available` | Il PV esiste ma non è ancora legato a nessun PVC |
| `Bound` | Il PV è legato a un PVC specifico |
| `Released` | Il PVC è stato eliminato, ma il PV non è ancora stato ripulito |
| `Failed` | Errore nel processo di reclaim automatico |

---

## 4. PersistentVolumeClaim (PVC)

Un **PersistentVolumeClaim** è una richiesta di storage avanzata da un Pod (o da un StatefulSet). Il Pod non sa nulla del backend fisico — dichiara solo le sue esigenze:

- quanta capacità gli serve (`storage: 10Gi`)
- quale modalità di accesso richiede (`ReadWriteOnce`)
- quale tipo di storage preferisce (`storageClassName: ceph-rbd`)

Kubernetes si occupa di trovare (o creare) un PV compatibile e di legarli insieme tramite il meccanismo di **binding**.

### Esempio di PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: persistence-trove-rabbitmq-server-0
  namespace: trove-messaging
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ceph-rbd
```

Nel caso del RabbitMQ Cluster Operator, i PVC **non vengono creati manualmente** — è il manifest `RabbitmqCluster` che, tramite il blocco `persistence`, istruisce l'Operator a generarli automaticamente per ogni replica del StatefulSet.

---

## 5. StorageClass e provisioning dinamico

La **StorageClass** definisce il "tipo" di storage disponibile nel cluster e il provisioner da usare per crearlo dinamicamente.

Esistono due modalità di provisioning:

**Statico**: l'amministratore crea manualmente i PV in anticipo. Il PVC viene legato al primo PV compatibile trovato.

**Dinamico**: quando viene creato un PVC con una `storageClassName` specificata, Kubernetes invoca automaticamente il provisioner della StorageClass che alloca lo storage fisico e crea il PV corrispondente. È il metodo usato nella nostra installazione.

| Ambiente | StorageClass | Backend |
|----------|-------------|---------|
| Produzione / Staging | `ceph-rbd` | Ceph RADOS Block Device |
| Locale con kind | `standard` | local-path-provisioner |

---

## 6. Ciclo di vita di PV e PVC

```
1. Il Cluster Operator legge il manifest RabbitmqCluster
           ↓
2. Crea un StatefulSet con volumeClaimTemplates
           ↓
3. Per ogni replica, Kubernetes crea un PVC
   (persistence-trove-rabbitmq-server-0, -1, -2)
           ↓
4. La StorageClass (ceph-rbd) riceve la richiesta
   e alloca fisicamente 10Gi su Ceph
           ↓
5. Viene creato il PV corrispondente
           ↓
6. PVC e PV vengono legati → STATUS: Bound
           ↓
7. Il Pod si avvia e monta il PVC
   su /var/lib/rabbitmq/mnesia/
           ↓
8. RabbitMQ scrive i suoi dati sul volume
```

Se il Pod viene riavviato o ricreato, riparte dal punto 7 — il PVC e il PV esistono già e vengono semplicemente rimontati. I dati sono intatti.

---

## 7. Access Modes

L'**Access Mode** definisce come un volume può essere montato rispetto ai Pod:

| Modalità | Abbreviazione | Descrizione |
|----------|--------------|-------------|
| `ReadWriteOnce` | RWO | Montato in lettura/scrittura da **un solo Pod** alla volta |
| `ReadOnlyMany` | ROX | Montato in sola lettura da **più Pod** contemporaneamente |
| `ReadWriteMany` | RWX | Montato in lettura/scrittura da **più Pod** contemporaneamente |
| `ReadWriteOncePod` | RWOP | Montato in lettura/scrittura da **un solo Pod** nell'intero cluster (più restrittivo di RWO) |

RabbitMQ usa **RWO** perché ogni nodo del cluster gestisce il proprio stato in modo indipendente. Non ha senso (ed è potenzialmente pericoloso) condividere lo stesso volume Mnesia tra più nodi contemporaneamente.

---

## 8. Reclaim Policy

La **Reclaim Policy** determina cosa succede al PV quando il PVC a esso associato viene eliminato:

| Policy | Comportamento |
|--------|--------------|
| `Delete` | Il PV e i dati fisici vengono eliminati automaticamente |
| `Retain` | Il PV rimane con i dati intatti, ma va in stato `Released` — richiede intervento manuale per essere riutilizzato |
| `Recycle` | Deprecato — eseguiva un `rm -rf` sul volume prima di renderlo disponibile |

Nel nostro ambiente, la policy è `Delete`:

```
RECLAIM POLICY   STATUS
Delete           Bound
```

Questo significa che se si elimina un PVC (ad esempio con `kubectl delete pvc persistence-trove-rabbitmq-server-0 -n trove-messaging`), il PV e tutti i dati vengono **cancellati permanentemente**. In produzione è buona pratica valutare l'uso di `Retain` per evitare perdite accidentali di dati.

---

## 9. Cosa contiene il volume di RabbitMQ

Il volume viene montato all'interno del container sul path:

```
/var/lib/rabbitmq/mnesia/<node-name>/
```

dove `<node-name>` è l'identità Erlang del nodo, ad esempio:
```
rabbit@trove-rabbitmq-server-0.trove-rabbitmq-nodes.trove-messaging
```

### Contenuto del volume

**Database Mnesia**
Mnesia è il database distribuito interno di Erlang, usato da RabbitMQ per memorizzare tutto lo stato del cluster:
- topologia del cluster (nodi membri)
- utenti e hash delle password
- permessi per vhost
- definizione di exchange, queue e binding
- vhost configurati

**Messaggi persistenti**
I messaggi pubblicati su code `durable` o di tipo `quorum` vengono scritti su disco. Sopravvivono a riavvii del broker e, nel caso delle quorum queue, sono replicati su tutti i nodi del cluster tramite il protocollo Raft.

**Quorum Queue data (Raft log)**
Le quorum queue usano un algoritmo di consensus (Raft) per garantire che ogni messaggio sia confermato da una maggioranza di nodi prima di essere considerato scritto. I log Raft vengono persistiti su disco in questa directory.

**Stream data**
Se si usano RabbitMQ Streams, i dati del log append-only vengono anch'essi persistiti sul volume.

### Cosa NON è persistito sul volume

- La configurazione dell'Operator (è nel ConfigMap)
- Le credenziali del default user (sono nel Secret Kubernetes)
- I messaggi sulle code `transient` (non durable) — queste vengono perse al riavvio per design

---

## 10. PVC in RabbitMQ Cluster Operator

Il Cluster Operator crea i PVC tramite il meccanismo `volumeClaimTemplates` del StatefulSet. Nel manifest `RabbitmqCluster`, il blocco che controlla questo comportamento è:

```yaml
spec:
  persistence:
    storageClassName: ceph-rbd   # quale StorageClass usare
    storage: 10Gi                # dimensione del volume
```

L'Operator traduce questa configurazione in un `volumeClaimTemplate` nel StatefulSet generato:

```yaml
volumeClaimTemplates:
  - metadata:
      name: persistence
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: ceph-rbd
      resources:
        requests:
          storage: 10Gi
```

Kubernetes crea quindi un PVC per ogni replica, con nome:
```
persistence-<cluster-name>-server-<ordinal>
```

Nel nostro caso:
```
persistence-trove-rabbitmq-server-0   →  nodo 0
persistence-trove-rabbitmq-server-1   →  nodo 1
persistence-trove-rabbitmq-server-2   →  nodo 2
```

Ogni PVC è **strettamente legato** alla sua replica — il pod `server-0` monta sempre e solo il PVC `server-0`, garantendo la consistenza dei dati.

---

## 11. Verifica dello stato dei volumi

```bash
# Verifica i PVC nel namespace trove-messaging
kubectl get pvc -n trove-messaging

# Output atteso:
# NAME                                  STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS
# persistence-trove-rabbitmq-server-0   Bound    pvc-10be...   10Gi       RWO            ceph-rbd
# persistence-trove-rabbitmq-server-1   Bound    pvc-22f1...   10Gi       RWO            ceph-rbd
# persistence-trove-rabbitmq-server-2   Bound    pvc-49d8...   10Gi       RWO            ceph-rbd

# Verifica i PV a livello cluster
kubectl get pv | grep trove-messaging

# Dettagli di un PVC specifico
kubectl describe pvc persistence-trove-rabbitmq-server-0 -n trove-messaging
```

Lo stato `Bound` su tutti e 3 i PVC indica che lo storage è correttamente allocato e ogni nodo RabbitMQ ha il suo volume dedicato.

---

## 12. Scenari di failure e resilienza

### Pod crash
Il Pod viene ricreato dal StatefulSet controller. Monta lo stesso PVC di prima e ritrova tutti i dati intatti. RabbitMQ esegue una recovery automatica dal database Mnesia.

### Nodo Kubernetes down
Il Pod viene reschedulo su un altro nodo disponibile. Il PVC (su Ceph) è accessibile da qualsiasi nodo del cluster K8s, quindi il Pod si riattacca al volume e riparte normalmente.

### Eliminazione accidentale del Pod
Stesso comportamento del caso precedente — il StatefulSet ricrea il Pod che rimonta il suo PVC.

### Eliminazione del PVC (irreversibile con policy Delete)
Il PV e tutti i dati vengono eliminati. Il Pod che prova a ripartire trova un volume vuoto e si unisce al cluster come nodo nuovo, sincronizzando i dati dagli altri nodi tramite peer discovery. **I messaggi non replicati su altri nodi vengono persi.**

### Eliminazione dell'intero RabbitmqCluster
Per default, eliminare la risorsa `RabbitmqCluster` **non elimina i PVC** — l'Operator li lascia intatti come misura di sicurezza. Questo permette di recuperare i dati in caso di eliminazione accidentale.
