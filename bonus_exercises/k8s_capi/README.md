## Prerequisiti

- Docker Desktop installato e in esecuzione
- Homebrew installato
- `kubectl` installato

---

## Step 1 — Installazione e configurazione di kind

### Installa kind

```bash
brew install kind
```

Installa kind (Kubernetes IN Docker) tramite Homebrew, uno strumento per creare cluster Kubernetes locali usando container Docker come nodi.

### Verifica la versione

```bash
kind version
```

Controlla che kind sia installato correttamente e mostra la versione installata.

### Crea il file di configurazione del cluster

```bash
cat > kind-cluster-with-extramounts.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  ipFamily: dual
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
EOF
```

Crea un file YAML di configurazione per il cluster kind con le seguenti impostazioni:

- `ipFamily: dual` — abilita il dual-stack networking (IPv4 + IPv6)
- `extraMounts` — monta il socket Docker dell'host (`/var/run/docker.sock`) all'interno del container del control-plane. Necessario affinché CAPD (Cluster API Docker Provider) possa creare nuovi container Docker come nodi dei workload cluster

### Crea il cluster kind

```bash
kind create cluster --config kind-cluster-with-extramounts.yaml
```

Crea il cluster Kubernetes locale usando il file di configurazione appena creato.

- `--config` — specifica il file di configurazione da utilizzare al posto dei valori di default

---

## Step 2 — Installazione di clusterctl

`clusterctl` è la CLI ufficiale di Cluster API per gestire il lifecycle dei cluster.

### Scarica il binario

```bash
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.4/clusterctl-darwin-amd64 -o clusterctl
```

Scarica il binario di `clusterctl` per macOS (amd64) da GitHub.

- `-L` — segue i redirect HTTP
- `-o clusterctl` — salva il file con il nome `clusterctl` nella directory corrente

### Rendi il binario eseguibile

```bash
chmod +x ./clusterctl
```

Aggiunge i permessi di esecuzione al binario scaricato.

### Sposta il binario nel PATH di sistema

```bash
sudo mv ./clusterctl /usr/local/bin/clusterctl
```

Sposta il binario in `/usr/local/bin` così da renderlo disponibile globalmente come comando.

### Verifica la versione

```bash
clusterctl version
```

Controlla che `clusterctl` sia installato correttamente e mostra la versione.

---

## Step 3 — Inizializzazione del management cluster

### Verifica il contesto attivo

```bash
kubectl cluster-info --context kind-kind
```

Verifica che il cluster kind sia il contesto Kubernetes attivo e che l'API server sia raggiungibile.

- `--context kind-kind` — specifica esplicitamente il contesto kind da usare (il nome default creato da kind è `kind-kind`)

### Abilita la feature ClusterClass

```bash
export CLUSTER_TOPOLOGY=true
```

Imposta la variabile d'ambiente che abilita la feature **ClusterClass** di Cluster API, necessaria per il flavor `development` e per gestire topologie avanzate di cluster.

### Inizializza Cluster API

```bash
clusterctl init --infrastructure docker
```

Installa tutti i componenti di Cluster API nel management cluster, inclusi:

- `cert-manager` — per la gestione dei certificati TLS interni
- `cluster-api` — i controller core di CAPI
- `bootstrap-kubeadm` — provider bootstrap per inizializzare i nodi con kubeadm
- `control-plane-kubeadm` — provider per la gestione del control plane
- `infrastructure-docker` (CAPD) — provider infrastruttura Docker per creare nodi come container

- `--infrastructure docker` — specifica il provider infrastruttura da installare (in questo caso Docker, per uso locale)

---

## Step 4 — Creazione del workload cluster

### Genera il manifest del cluster

```bash
clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.36.1 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > capi-quickstart.yaml
```

Genera il manifest YAML per creare un workload cluster e lo salva nel file `capi-quickstart.yaml`.

- `capi-quickstart` — nome del cluster da creare
- `--flavor development` — usa il template `development` preconfigurato per CAPD, adatto a uso locale
- `--kubernetes-version v1.36.1` — versione di Kubernetes da installare nel workload cluster
- `--control-plane-machine-count=1` — numero di nodi control-plane (1 per ambiente di test)
- `--worker-machine-count=1` — numero di nodi worker (1 per ambiente di test)
- `> capi-quickstart.yaml` — redirige l'output su file invece di applicarlo direttamente

### Applica il manifest

```bash
kubectl apply -f capi-quickstart.yaml
```

Applica il manifest al management cluster, avviando la creazione del workload cluster.

- `-f capi-quickstart.yaml` — specifica il file manifest da applicare

### Verifica lo stato del cluster

```bash
kubectl get cluster
```

Mostra la lista dei cluster gestiti da Cluster API e il loro stato corrente.

### Descrivi il cluster in dettaglio

```bash
clusterctl describe cluster capi-quickstart
```

Mostra una vista ad albero dello stato di tutte le risorse del cluster (machines, control plane, worker), utile per monitorare il processo di provisioning.

---

## Step 5 — Installazione del CNI (Calico)

I nodi del workload cluster rimangono in stato `NotReady` finché non viene installato un CNI (Container Network Interface).

### Recupera il kubeconfig del workload cluster

```bash
clusterctl get kubeconfig capi-quickstart > capi-quickstart.kubeconfig
```

Scarica il kubeconfig del workload cluster e lo salva in un file locale.

> ⚠️ **Nota:** L'IP nel kubeconfig potrebbe puntare all'IP interno Docker (es. `172.18.0.x`) non raggiungibile dal Mac. Verifica con `cat capi-quickstart.kubeconfig | grep server` e se necessario sostituiscilo con `127.0.0.1` e la porta esposta da Docker:
>
> ```bash
> # Trova la porta esposta dal control plane
> docker port <nome-container-control-plane>
>
> # Sostituisci l'IP con Python
> python3 -c "
> with open('capi-quickstart.kubeconfig', 'r') as f:
>     content = f.read()
> content = content.replace('172.18.0.3:6443', '127.0.0.1:<porta>')
> with open('capi-quickstart.kubeconfig', 'w') as f:
>     f.write(content)
> "
> ```

### Installa Calico sul workload cluster

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig \
  apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

Installa il CNI Calico nel workload cluster.

- `--kubeconfig=capi-quickstart.kubeconfig` — specifica il kubeconfig del workload cluster (non del management cluster kind)

### Monitora i nodi in tempo reale

```bash
watch -n 10 "kubectl --kubeconfig=capi-quickstart.kubeconfig get nodes"
```

Esegue il comando ogni 10 secondi per monitorare quando i nodi passano da `NotReady` a `Ready`.

- `-n 10` — intervallo di aggiornamento in secondi

### Verifica i pod di sistema

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig get pods -n kube-system
```

Controlla che i pod di Calico e CoreDNS siano in stato `Running`.

- `-n kube-system` — filtra i pod nel namespace `kube-system`

### Verifica lo stato finale del cluster

```bash
clusterctl describe cluster capi-quickstart
```

Tutti i componenti devono mostrare `True` / `Available` / `Ready`.

---

## Step 6 — Deploy dell'applicazione di esempio (nginx)

### Crea il deployment

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig \
  create deployment nginx --image=nginx:latest --replicas=2
```

Crea un deployment di nginx con 2 repliche nel workload cluster.

- `--image=nginx:latest` — immagine Docker da usare
- `--replicas=2` — numero di pod da avviare

### Esponi il deployment

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig \
  expose deployment nginx --port=80 --type=NodePort
```

Crea un Service per esporre il deployment nginx.

- `--port=80` — porta su cui nginx è in ascolto all'interno del pod
- `--type=NodePort` — espone il service su una porta casuale di ogni nodo (range 30000-32767)

### Verifica i pod

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig get pods
```

Controlla che i pod nginx siano in stato `Running`.

### Verifica il service

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig get svc nginx
```

Mostra il service nginx con la porta NodePort assegnata (es. `80:30495/TCP`).

### Accedi all'applicazione via port-forward

```bash
kubectl --kubeconfig=capi-quickstart.kubeconfig \
  port-forward svc/nginx 8080:80
```

Crea un tunnel tra la porta `8080` del tuo Mac e la porta `80` del service nginx nel cluster.

- `svc/nginx` — il service da cui fare il forward
- `8080:80` — `<porta-locale>:<porta-del-service>`

### Apri il browser