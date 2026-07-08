# Gestione dei Secret in Kubernetes

## Obiettivo dell'esercizio

L'obiettivo di questo esercizio è imparare a creare e gestire i **Secret** in Kubernetes, visualizzarne il contenuto, modificarli e utilizzarli all'interno di un Pod come variabili d'ambiente.

---

# Comandi iniziali

Verificare che Minikube sia installato.

```bash
minikube version
```

Questo comando mostra la versione installata di Minikube.

Avviare il cluster Kubernetes locale.

```bash
minikube start
```

Il comando crea e avvia un cluster Kubernetes sul computer.

Visualizzare i nodi del cluster.

```bash
kubectl get nodes
```

Mostra l'elenco delle macchine (fisiche o virtuali) che compongono il cluster Kubernetes.

---

# Creazione del primo Secret

Creare un Secret contenente username e password.

```bash
kubectl create secret generic user-pass \
  --from-literal=username=mery \
  --from-literal=password=1234
```

Il comando crea un Secret chiamato `user-pass` utilizzando due coppie chiave-valore.

Visualizzare tutti i Secret presenti.

```bash
kubectl get secrets
```

Mostra tutti i Secret presenti nel namespace corrente.

---

# Visualizzazione del Secret in formato YAML

Visualizzare il Secret appena creato.

```bash
kubectl get secret user-pass -o yaml
```

Il comando restituisce il Secret in formato YAML.

Esempio di output:

```yaml
apiVersion: v1
data:
  password: MTIzNA==
  username: bWVyeQ==
kind: Secret
metadata:
  creationTimestamp: "2026-07-07T10:32:37Z"
  name: user-pass
  namespace: default
  resourceVersion: "52115"
  uid: 5f27996f-49bc-4388-b74c-e1578b36fde2
type: Opaque
```

Si può notare che username e password sono memorizzati in formato **Base64**.

---

# Decodifica dei dati

Decodificare lo username.

```bash
echo -n 'bWVyeQ==' | base64 --decode
```

Restituisce il valore originale dello username.

Decodificare la password.

```bash
echo -n 'MTIzNA==' | base64 --decode
```

Restituisce il valore originale della password.

> **Nota:** la codifica Base64 non rappresenta una forma di cifratura. I dati possono essere decodificati facilmente da chiunque e non garantiscono la protezione delle informazioni sensibili.

---

# Salvare il Secret in un file YAML

Esportare il Secret in un file.

```bash
kubectl get secret user-pass -o yaml > secret-new.yaml
```

Il comando salva la rappresentazione YAML del Secret all'interno del file `secret-new.yaml`.

---

# Modifica del Secret

Aprire il file appena creato.

```bash
vim secret-new.yaml
```

Dal file rimuovere i campi generati automaticamente da Kubernetes:

* `creationTimestamp`
* `resourceVersion`
* `uid`

Generare il nuovo username codificato.

```bash
echo -n 'admin' | base64
```

Generare la nuova password codificata.

```bash
echo -n '4321' | base64
```

Sostituire i valori presenti nel file con quelli appena ottenuti e modificare il nome del Secret.

Il file finale sarà simile al seguente:

```yaml
apiVersion: v1
data:
  password: NDMyMQ==
  username: YWRtaW4=
kind: Secret
metadata:
  name: user-pass2
  namespace: default
type: Opaque
```

---

# Creazione del nuovo Secret

Verificare che il file YAML sia corretto.

```bash
kubectl apply -f secret-new.yaml --dry-run=client
```

Se il comando non restituisce errori, il file è valido.

Creare il nuovo Secret.

```bash
kubectl apply -f secret-new.yaml
```

Applicare il file YAML creando il nuovo Secret.

Visualizzare i Secret disponibili.

```bash
kubectl get secrets
```

Il nuovo Secret `user-pass2` sarà presente nell'elenco.

---

# Creazione del Pod

Creare il file di configurazione del Pod.

```bash
vim secret-pod.yaml
```

Inserire il seguente contenuto:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secret-test-pod
spec:
  containers:
    - name: test-container
      image: busybox
      command: ["sleep", "3600"]
      env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: user-pass2
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: user-pass2
              key: password
```

Il Pod utilizza il Secret `user-pass2` per valorizzare due variabili d'ambiente:

* `SECRET_USERNAME`
* `SECRET_PASSWORD`

---

# Creazione del Pod nel cluster

Applicare il file YAML.

```bash
kubectl apply -f secret-pod.yaml
```

Il comando crea il Pod nel cluster Kubernetes.

Verificare che il Pod sia stato creato.

```bash
kubectl get pods
```

Se tutto è corretto il Pod risulterà nello stato **Running**.

---

# Verifica delle variabili d'ambiente

Accedere alla shell del container.

```bash
kubectl exec -it secret-test-pod -- sh
```

Una volta entrati nel container, verificare il contenuto delle variabili d'ambiente.

```bash
echo $SECRET_USERNAME
```

Visualizza lo username memorizzato nel Secret.

```bash
echo $SECRET_PASSWORD
```

Visualizza la password memorizzata nel Secret.

Per uscire dal container:

```bash
exit
```

Questo dimostra che il Secret viene reso disponibile all'interno del Pod come variabile d'ambiente e che il suo contenuto è leggibile in chiaro durante l'esecuzione del container.

---

# Concetti appresi

Con questo esercizio è stato possibile imparare a:

* creare Secret in Kubernetes;
* visualizzare un Secret in formato YAML;
* comprendere la codifica Base64 utilizzata da Kubernetes;
* modificare un Secret esportandolo in un file YAML;
* creare risorse Kubernetes tramite `kubectl apply`;
* utilizzare un Secret come variabile d'ambiente all'interno di un Pod;
* verificare il funzionamento del Secret direttamente dall'interno del container.

---

# Comandi principali utilizzati

Verifica di Minikube:

```bash
minikube version
```

Avvio del cluster:

```bash
minikube start
```

Visualizzazione dei nodi:

```bash
kubectl get nodes
```

Creazione del Secret:

```bash
kubectl create secret generic user-pass --from-literal=username=mery --from-literal=password=1234
```

Visualizzazione dei Secret:

```bash
kubectl get secrets
```

Visualizzazione del Secret in YAML:

```bash
kubectl get secret user-pass -o yaml
```

Esportazione del Secret:

```bash
kubectl get secret user-pass -o yaml > secret-new.yaml
```

Creazione del nuovo Secret:

```bash
kubectl apply -f secret-new.yaml
```

Creazione del Pod:

```bash
kubectl apply -f secret-pod.yaml
```

Verifica dei Pod:

```bash
kubectl get pods
```

Accesso al container:

```bash
kubectl exec -it secret-test-pod -- sh
```
