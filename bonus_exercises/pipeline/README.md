# Pipeline Jenkins con esecuzione solo nei giorni feriali

## Obiettivo

Realizzare una pipeline Jenkins che esegua una build esclusivamente dal **lunedì al venerdì** e che blocchi l’esecuzione durante il **sabato e la domenica**, mostrando un messaggio di warning.

Come richiesto dall’esercizio, il controllo del giorno corrente viene effettuato utilizzando l’oggetto **Date** del linguaggio **Groovy**, senza utilizzare comandi shell esterni.

---

## Descrizione della pipeline

La pipeline è composta da due stage principali:

* **Check Giorno** → verifica il giorno corrente e decide se consentire o meno l’esecuzione della build.
* **Build** → esegue la build solamente se il controllo iniziale ha avuto esito positivo.

---

## Funzionamento del codice

### 1. Definizione della pipeline

La pipeline viene eseguita su qualsiasi agente Jenkins disponibile:

```groovy id="a1"
pipeline {
    agent any
```

L’istruzione `agent any` permette di utilizzare qualunque nodo disponibile per l’esecuzione del job.

---

### 2. Controllo del giorno corrente

Nel primo stage viene creato un oggetto `Date` di Groovy per ottenere la data attuale:

```groovy id="a2"
def oggi = new Date()
def giorno = oggi.day
```

La variabile `giorno` restituisce un numero che identifica il giorno della settimana:

* `0` = Domenica
* `6` = Sabato
* valori da `1` a `5` = Giorni feriali

---

### 3. Verifica weekend

Successivamente viene controllato se il giorno corrente corrisponde al weekend:

```groovy id="a3"
if (giorno == 0 || giorno == 6)
```

Se il giorno è **sabato o domenica**, Jenkins:

* mostra un messaggio di warning;
* interrompe la pipeline;
* imposta la build come annullata.

```groovy id="a4"
echo "WARNING: Oggi è sabato o domenica. La build non verrà eseguita."
currentBuild.result = 'ABORTED'
error("Build disabilitata nel weekend.")
```

In questo modo la build non prosegue.

---

### 4. Esecuzione nei giorni feriali

Se il giorno corrente non è weekend, viene mostrato un messaggio di conferma:

```groovy id="a5"
echo "Giorno feriale. Avvio build..."
```

La pipeline continua normalmente passando allo stage successivo.

---

### 5. Esecuzione della build

Nel secondo stage viene simulata l’esecuzione della build:

```groovy id="a6"
stage('Build') {
    steps {
        echo "Build in esecuzione!"
    }
}
```

Questo stage viene eseguito solo dal **lunedì al venerdì**.

---

## Risultato finale

La pipeline permette di:

* controllare il giorno corrente tramite l’oggetto `Date` di Groovy;
* consentire l’esecuzione della build solo nei giorni lavorativi;
* bloccare automaticamente la pipeline durante il weekend;
* mostrare un messaggio di warning quando la build non può essere eseguita.

