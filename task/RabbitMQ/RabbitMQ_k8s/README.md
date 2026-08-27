# Documentazione Tecnica — RabbitMQ Cluster Operator su Kubernetes

## Installazione del Cluster Operator

Il Cluster Operator viene installato applicando il manifest ufficiale rilasciato da RabbitMQ. Il manifest crea automaticamente:

- Il namespace `rabbitmq-system`
- Le Custom Resource Definitions (CRD) — tra cui `RabbitmqCluster`
- Il ServiceAccount, ClusterRole e ClusterRoleBinding necessari
- Il Deployment dell'operator

```bash
kubectl apply -f https://github.com/rabbitmq/cluster-operator/releases/download/v2.16.1/cluster-operator.yml
```

### Verifica installazione

```bash
# Verifica che il namespace sia stato creato
kubectl get ns

# Verifica che il pod dell'operator sia in esecuzione
kubectl get pods -n rabbitmq-system
```

Output atteso:

```
NAME                                        READY   STATUS    RESTARTS   AGE
rabbitmq-cluster-operator-76d998c6dd-78x4j  1/1     Running   0          2m
```

---

## Troubleshooting — ImageInspectError

### Problema riscontrato

Dopo l'installazione il pod dell'operator rimaneva in stato `ImageInspectError`. Ispezionando il pod:

```bash
kubectl describe pod -n rabbitmq-system rabbitmq-cluster-operator-76d998c6dd-78x4j
```

L'output mostrava il seguente errore negli Events:

```
Warning  InspectFailed  kubelet  Failed to inspect image "": rpc error: code = Unknown
desc = short-name "rabbitmqoperator/cluster-operator:2.16.1" did not resolve to an
alias and no unqualified-search registries are defined in
"/etc/containers/registries.conf.d/01-unqualified.conf"

Warning  Failed  kubelet  Error: ImageInspectError
```

### Causa

Il cluster Kubernetes aziendale utilizza un runtime container (probabilmente **CRI-O**) che non risolve automaticamente i **short name** delle immagini — cioè nomi senza il registry esplicito come `docker.io/` davanti.

Il manifest ufficiale di RabbitMQ specifica l'immagine come:

```
rabbitmqoperator/cluster-operator:2.16.1
```

Senza il prefisso `docker.io/`, il runtime non sa da quale registry scaricarla e fallisce.

### Soluzione

Esportare il Deployment dell'operator in un file YAML, modificare il campo `image` aggiungendo il registry esplicito `docker.io/`, e riapplicare il manifest modificato.

---

## Fix del Deployment

### Step 1 — Esporta il Deployment

```bash
kubectl get deployment rabbitmq-cluster-operator -n rabbitmq-system -o yaml > deployment.yaml
```

### Step 2 — Modifica il campo image

Nel file `deployment.yaml`, nella sezione `spec.template.spec.containers`, modificare il campo `image`:

```yaml
# Prima (causava ImageInspectError)
image: rabbitmqoperator/cluster-operator:2.16.1

# Dopo (registry esplicito)
image: docker.io/rabbitmqoperator/cluster-operator:2.16.1
```

### Step 3 — Riapplica il Deployment modificato

```bash
kubectl apply -f deployment.yaml -n rabbitmq-system
```

### Step 4 — Verifica

```bash
kubectl get pods -n rabbitmq-system
```

Il pod deve passare in stato `Running` con `READY 1/1`.

### deployment.yaml completo

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq-cluster-operator
  namespace: rabbitmq-system
  labels:
    app.kubernetes.io/component: rabbitmq-operator
    app.kubernetes.io/name: rabbitmq-cluster-operator
    app.kubernetes.io/part-of: rabbitmq
spec:
  replicas: 1
  revisionHistoryLimit: 10
  progressDeadlineSeconds: 600
  selector:
    matchLabels:
      app.kubernetes.io/name: rabbitmq-cluster-operator
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app.kubernetes.io/component: rabbitmq-operator
        app.kubernetes.io/name: rabbitmq-cluster-operator
        app.kubernetes.io/part-of: rabbitmq
    spec:
      serviceAccountName: rabbitmq-cluster-operator
      terminationGracePeriodSeconds: 10
      containers:
        - name: operator
          image: docker.io/rabbitmqoperator/cluster-operator:2.16.1
          imagePullPolicy: IfNotPresent
          command:
            - /manager
          env:
            - name: OPERATOR_NAMESPACE
              valueFrom:
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
          ports:
            - name: metrics
              containerPort: 9782
              protocol: TCP
          resources:
            limits:
              cpu: 200m
              memory: 500Mi
            requests:
              cpu: 200m
              memory: 500Mi
          terminationMessagePath: /dev/termination-log
          terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
```

---

## Deploy del cluster RabbitMQ

Con l'operator in esecuzione, il cluster RabbitMQ viene creato applicando una risorsa `RabbitmqCluster` — una Custom Resource Definition introdotta dall'operator stesso.

### Step 1 — Crea il namespace applicativo

```bash
kubectl create namespace trove-messaging
```

Il namespace `trove-messaging` ospita il cluster RabbitMQ dedicato all'applicazione Trove, separato dal namespace `rabbitmq-system` che contiene solo l'operator.

### Step 2 — Applica il manifest RabbitmqCluster

```bash
kubectl apply -f rabbitmq-trove-cluster.yaml
```

### rabbitmq-trove-cluster.yaml completo

```yaml
apiVersion: rabbitmq.com/v1beta1
kind: RabbitmqCluster
metadata:
  name: trove-rabbitmq
  namespace: trove-messaging
spec:
  replicas: 3
  image: docker.io/library/rabbitmq:4.1.3-management

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

## Configurazione dettagliata

### replicas: 3

Definisce il numero di Pod RabbitMQ nel cluster. L'operator crea uno **StatefulSet** con 3 repliche, ognuna con il proprio PersistentVolumeClaim. La scelta di 3 nodi segue la logica del quorum — il cluster rimane operativo anche con 1 nodo non disponibile.

### image

```yaml
image: docker.io/library/rabbitmq:4.1.3-management
```

Usa il registry esplicito `docker.io` per lo stesso motivo del fix all'operator — evitare l'errore di risoluzione degli short name. Il tag `-management` include la Management UI integrata.

### resources

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

- **requests** — risorse garantite che Kubernetes riserva per ogni Pod
- **limits** — tetto massimo che ogni Pod può consumare
- `500m` CPU = mezzo core; `2` CPU = due core interi

### persistence

```yaml
persistence:
  storageClassName: ceph-rbd
  storage: 10Gi
```

Ogni Pod riceve un **PersistentVolumeClaim** da 10Gi sulla storage class `ceph-rbd` (Ceph RADOS Block Device — lo storage distribuito del cluster aziendale). I dati di RabbitMQ vengono scritti su questo volume e sopravvivono al riavvio dei Pod.

### Service — NodePort

```yaml
override:
  service:
    spec:
      type: NodePort
      ports:
        - name: amqp
          port: 5672
          targetPort: 5672
          nodePort: 30672
```

Espone la porta AMQP (5672) all'esterno del cluster sulla porta `30672` di ogni nodo worker. Questo permette alle applicazioni esterne al cluster Kubernetes di connettersi a RabbitMQ.

### podAntiAffinity

```yaml
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

Garantisce che i 3 Pod RabbitMQ vengano schedulati su **nodi fisici diversi** del cluster Kubernetes. Se due Pod finissero sullo stesso nodo fisico e quel nodo cadesse, si perderebbero 2 dei 3 nodi RabbitMQ compromettendo il quorum. Con `requiredDuringSchedulingIgnoredDuringExecution` Kubernetes **non schedula** il Pod se non trova un nodo fisico libero — è un vincolo hard, non una preferenza.

---

## Verifica del deploy

### Step 1 — Monitora la creazione dei Pod

```bash
kubectl get pods -n trove-messaging -w
```

Il flag `-w` (watch) tiene il comando in ascolto e mostra in tempo reale i cambi di stato dei Pod, utile per seguire l'avvio progressivo dei 3 nodi del cluster senza dover rilanciare il comando manualmente.

Output atteso, una volta completato l'avvio:

```
NAME                     READY   STATUS    RESTARTS   AGE
trove-rabbitmq-server-0  1/1     Running   0          5m
trove-rabbitmq-server-1  1/1     Running   0          4m
trove-rabbitmq-server-2  1/1     Running   0          3m
```

### Step 2 — Verifica generale delle risorse create

```bash
# Verifica i pod del cluster RabbitMQ
kubectl get pods -n trove-messaging

# Verifica il cluster RabbitMQ
kubectl get rabbitmqcluster -n trove-messaging

# Dettagli della risorsa
kubectl describe rabbitmqcluster trove-rabbitmq -n trove-messaging
```

### Step 3 — Verifica il cluster

```bash
# Status del cluster
kubectl exec -n trove-messaging trove-rabbitmq-server-0 -- rabbitmqctl cluster_status

# Credenziali default (generate dall'Operator)
kubectl get secret -n trove-messaging trove-rabbitmq-default-user -o jsonpath='{.data.username}' | base64 -d
kubectl get secret -n trove-messaging trove-rabbitmq-default-user -o jsonpath='{.data.password}' | base64 -d

# Management UI (port forward per test)
kubectl port-forward -n trove-messaging svc/trove-rabbitmq 15672:15672 &
# Apri http://localhost:15672 con le credenziali sopra
```

`rabbitmqctl cluster_status` conferma che i 3 nodi si sono uniti correttamente allo stesso cluster (sezione `Running Nodes`). Le credenziali del secret `trove-rabbitmq-default-user` sono generate automaticamente dall'Operator alla creazione del cluster e permettono un primo accesso di verifica, sia da CLI che dalla Management UI.

---