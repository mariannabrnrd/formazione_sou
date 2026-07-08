# Gestione dei Secret in Kubernetes

## Comandi iniziali

```bash
minikube version
```
Per verificare se è installato e che versione.

```bash
minikube start
```
Per far partire un piccolo cluster di Kubernetes sul nostro computer.

```bash
kubectl get nodes
```
Mostra l'elenco di tutte le macchine (fisiche o virtuali) che compongono il cluster Kubernetes.

---

## Creazione primo Secret con --from-literal

```bash
kubectl create secret generic user-pass --from-literal=username=mery --from-literal=password=1234
```
Creiamo il nostro primo Secret "user-pass" inserendo username e password.

```bash
kubectl get secrets
```
Elenca tutti i Secret presenti nel Namespace attivo di Kubernetes.

---

## Visualizzazione del Secret in formato YAML

```bash
kubectl get secret user-pass -o yaml
```
Ci mostra il nostro Secret scritto in formato YAML:

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

```bash
echo -n 'bWVyeQ==' | base64 --decode
echo -n 'MTIzNA==' | base64 --decode
```
Nel Secret le informazioni inserite sono codificate in base64; per decodificarle basta prendere la stringa codificata e, tramite echo e una pipeline (|), passarla come input al comando base64 --decode, che la riporta al valore originale in chiaro.

Nota: la codifica base64 non è cifratura, è solo una rappresentazione: chiunque può decodificarla senza bisogno di una chiave segreta.

---

## Salvare il YAML su un file

```bash
kubectl get secret user-pass -o yaml > secret-new.yaml
```
Prende l'output del Secret scritto in YAML e lo salva in un file dedicato grazie alla redirezione.

---

## Modificare il file per il nuovo Secret

```bash
vim secret-new.yaml
```
Usiamo questo comando per entrare nel file da modificare. Leviamo i campi che non sono importanti come creationTimestamp, resourceVersion e uid.

```bash
echo -n 'admin' | base64
echo -n '4321' | base64
```
Sostituiamo i valori con quelli presenti nel file creato:

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

## Creiamo il nuovo Secret

```bash
kubectl apply -f secret-new.yaml --dry-run=client
```
Se questo comando non dà errori, possiamo applicare/creare il nuovo Secret.

```bash
kubectl apply -f secret-new.yaml
```
Applichiamo quello che abbiamo scritto, creando così il nuovo Secret.

```bash
kubectl get secrets
```
Per visualizzare i Secret presenti.

---

## Creiamo un Pod che usa un Secret come variabile d'ambiente

```bash
vim secret-pod.yaml
```
Creiamo il file di configurazione per il Pod:

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

```bash
kubectl apply -f secret-pod.yaml
```
Applichiamo la configurazione per il Pod, così da crearlo.

```bash
kubectl get pods
```
Per verificare che sia stato creato il Pod e che sia in stato Running.

---

## Verificare dentro il Pod

```bash
kubectl exec -it secret-test-pod -- sh
```
Questo comando ci permette di aprire una shell dentro il container.

```bash
echo $SECRET_USERNAME
echo $SECRET_PASSWORD
exit
```
Verifichiamo che il Pod veda le variabili d'ambiente che abbiamo impostato con il Secret.

Questo dimostra che dentro il container il Secret è leggibile in chiaro come variabile d'ambiente — ulteriore motivo per cui la codifica base64 da sola non garantisce la sicurezza dei dati sensibili (vedi bonus: encryption at rest).

