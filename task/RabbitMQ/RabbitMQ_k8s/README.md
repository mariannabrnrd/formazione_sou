# Documentazione Tecnica — RabbitMQ Cluster Operator su Kubernetes

## Indice

1. [Introduzione](#1-introduzione)
2. [Installazione del Cluster Operator](#2-installazione-del-cluster-operator)
3. [Deploy del cluster RabbitMQ](#3-deploy-del-cluster-rabbitmq)
4. [Configurazione dettagliata del manifest](#4-configurazione-dettagliata-del-manifest)
5. [Verifica del deploy](#5-verifica-del-deploy)
6. [Creazione di vhost e utenti dedicati](#6-creazione-di-vhost-e-utenti-dedicati)
7. [Esporre RabbitMQ alle VM Trove](#7-esporre-rabbitmq-alle-vm-trove)

---

## 1. Introduzione

RabbitMQ viene deployato su Kubernetes perché Trove (il servizio OpenStack per il Database as a Service) utilizza un sistema di code di messaggi per coordinare le comunicazioni tra il suo componente di controllo (trove-conductor) e gli agenti che girano sulle VM dei database (trove-guestagent). Ogni operazione — creare un database, fare un backup, scalare un'istanza — viene inviata come messaggio sulla coda e l'agente sulla VM la esegue in modo asincrono.

Deployarlo su Kubernetes permette di gestirlo come un servizio infrastrutturale stabile, con alta disponibilità garantita dai 3 nodi, storage persistente tramite Ceph e ciclo di vita gestito dall'Operator.


---

## 2. Installazione del Cluster Operator

Il Cluster Operator viene installato applicando il manifest ufficiale rilasciato da RabbitMQ. Il manifest crea automaticamente:

- Il namespace `rabbitmq-system`
- Le Custom Resource Definitions (CRD) — tra cui `RabbitmqCluster`
- Il ServiceAccount, ClusterRole e ClusterRoleBinding necessari
- Il Deployment dell'Operator

```bash
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml
```

### Verifica installazione

```bash
kubectl get pods -n rabbitmq-system
```

Output atteso:

```
NAME                                         READY   STATUS    RESTARTS   AGE
rabbitmq-cluster-operator-76d998c6dd-78x4j   1/1     Running   0          2m
```

---

## 3. Deploy del cluster RabbitMQ

Con l'Operator in esecuzione, il cluster RabbitMQ viene creato applicando una risorsa `RabbitmqCluster` — una Custom Resource Definition introdotta dall'Operator stesso. Quando viene applicata, l'Operator la intercetta tramite il suo Control Loop e crea automaticamente tutta l'infrastruttura necessaria: StatefulSet, Service, Secret, ConfigMap e RoleBinding.

### Step 1 — Crea il namespace applicativo

```bash
kubectl create namespace trove-messaging
```

Il namespace `trove-messaging` ospita il cluster RabbitMQ dedicato all'applicazione Trove, separato dal namespace `rabbitmq-system` che contiene solo l'Operator.

### Step 2 — Applica il manifest RabbitmqCluster

```bash
kubectl apply -f rabbitmq-trove-cluster.yaml
```

### rabbitmq-trove-cluster.yaml

```yaml
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: trove-rabbitmq
  namespace: trove-messaging
spec:
  replicas: 3
  image: rabbitmq:4.1-management

  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "2"
      memory: "4Gi"

  persistence:
    storageClassName: ceph-rbd
    storage: 10Gi

  rabbitmq:
    additionalConfig: |
      default_queue_type = quorum
      channel_max = 2047
      heartbeat = 60
      cluster_formation.peer_discovery_backend = rabbit_peer_discovery_k8s
      cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
      cluster_formation.k8s.address_type = hostname
      cluster_formation.node_cleanup.interval = 30
      cluster_formation.node_cleanup.only_log_warning = true

  override:
    service:
      spec:
        type: NodePort
        ports:
          - name: amqp
            port: 5672
            targetPort: 5672
            nodePort: 30672
    statefulSet:
      spec:
        template:
          spec:
            containers:
              - name: rabbitmq
            affinity:
              podAntiAffinity:
                requiredDuringSchedulingIgnoredDuringExecution:
                  - labelSelector:
                      matchExpressions:
                        - key: app.kubernetes.io/name
                          operator: In
                          values:
                            - trove-rabbitmq
                    topologyKey: kubernetes.io/hostname
```

---

## 5. Verifica del deploy

### Monitora la creazione dei Pod

```bash
kubectl get pods -n trove-messaging -w
```

Output atteso:

```
NAME                      READY   STATUS    RESTARTS   AGE
trove-rabbitmq-server-0   1/1     Running   0          5m
trove-rabbitmq-server-1   1/1     Running   0          4m
trove-rabbitmq-server-2   1/1     Running   0          3m
```

---

### Verifica generale delle risorse create

```bash
# Verifica il cluster RabbitMQ
kubectl get rabbitmqcluster -n trove-messaging

# Verifica i PersistentVolumeClaim
kubectl get pvc -n trove-messaging

# Verifica il Service
kubectl get svc -n trove-messaging
```

### Verifica lo stato del cluster RabbitMQ

```bash
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- rabbitmqctl cluster_status
```

Conferma che i 3 nodi si siano uniti correttamente allo stesso cluster (sezione `Running Nodes`).

### Accedi alla Management UI

```bash
# Recupera le credenziali generate automaticamente dall'Operator
kubectl get secret -n trove-messaging trove-rabbitmq-default-user -o jsonpath='{.data.username}' | base64 -d
echo ""
kubectl get secret -n trove-messaging trove-rabbitmq-default-user -o jsonpath='{.data.password}' | base64 -d
echo ""

# Port forward per accedere alla UI
kubectl port-forward -n trove-messaging svc/trove-rabbitmq 15672:15672
```

Apri `http://localhost:15672` con le credenziali recuperate.

---


## 6. Creazione di vhost e utenti dedicati

Si è optato per un isolamento: un vhost dedicato con relativo utente (`trove-roma` e `trove-milano`). Ogni utente ha permessi completi solo sul proprio vhost, isolato dagli altri.

```bash
# Vhost e utente "trove-roma"
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl add_vhost trove-roma
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl add_user trove-roma <PASSWORD-SICURA>
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl set_permissions -p trove-roma trove-roma ".*" ".*" ".*"

# Vhost e utente "trove-milano"
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl add_vhost trove-milano
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl add_user trove-milano <PASSWORD-SICURA>
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- \
  rabbitmqctl set_permissions -p trove-milano trove-milano ".*" ".*" ".*"
```

### Verifica

```bash
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- rabbitmqctl list_users
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- rabbitmqctl list_vhosts
```

Output atteso:

```
# list_users
user                               tags
default_user_Zcm1ysisBFOvU6KkDur   [administrator]
trove-roma                         []
trove-milano                       []

# list_vhosts
name
/
trove-roma
trove-milano
```

L'utente `default_user_...` con tag `[administrator]` è generato automaticamente dall'Operator e va usato solo per amministrazione, non dalle applicazioni.

---

## 7. Esporre RabbitMQ alle VM Trove


La configurazione NodePort è già inclusa nel manifest `rabbitmq-trove-cluster.yaml`. Con `type: NodePort`, Kubernetes apre la porta `30672` su ogni nodo worker del cluster: una VM Trove può connettersi a RabbitMQ puntando all'IP di un qualsiasi nodo worker sulla porta `30672`.

### Verifica del NodePort

```bash
kubectl get svc -n trove-messaging trove-rabbitmq
```

Output atteso:

```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
trove-rabbitmq   NodePort   10.96.123.45    <none>        5672:30672/TCP   10m
```

Recupera l'IP di un nodo worker:

```bash
kubectl get nodes -o wide
```

L'endpoint da usare nella connection string delle VM Trove sarà:

```
<IP-NODO-WORKER>:30672
```
