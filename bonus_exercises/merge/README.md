# Gestione di un conflitto con Git Merge

## Obiettivo

Simulare un conflitto durante un’operazione di merge tra branch differenti e risolverlo utilizzando i comandi Git da terminale.

---

## Procedimento svolto

### 1. Creazione di un secondo branch

Per iniziare, è stato creato un secondo branch di lavoro chiamato:

```bash
git branch nome_1
```

Successivamente mi sono spostata sul nuovo branch tramite:

```bash
git switch nome_1
```

---

### 2. Modifica dei file sui due branch

Ho lavorato su entrambi i branch (`main` e `nome_1`), modificando più volte gli stessi file.

Per passare da un branch all’altro ho utilizzato il comando:

```bash
git switch main
```

oppure

```bash
git switch nome_1
```

Dopo ogni modifica ho eseguito i normali comandi di salvataggio:

```bash
git add .
git commit -m "messaggio commit"
```

---

### 3. Generazione del conflitto

Una volta terminate le modifiche, sono tornata sul branch principale:

```bash
git switch main
```

Successivamente ho avviato il merge del secondo branch:

```bash
git merge nome_1
```

Poiché gli stessi file erano stati modificati in modo differente nei due branch, Git ha generato volutamente un **merge conflict**.

---

### 4. Risoluzione del conflitto

Per risolvere il conflitto tramite terminale ho scelto quale versione dei file mantenere utilizzando i seguenti comandi.

Per mantenere la versione presente nel branch corrente (`main`):

```bash
git checkout --ours file1.txt
```

Per mantenere la versione proveniente dal branch unito (`nome_1`):

```bash
git checkout --theirs file1.txt
```

In questo modo ho deciso manualmente quale contenuto conservare.

---

### 5. Conferma della risoluzione

Dopo aver risolto il conflitto, ho aggiunto nuovamente i file all’area di staging:

```bash
git add .
```

Successivamente ho creato un commit finale per registrare la risoluzione:

```bash
git commit -m "risoluzione conflitti"
```

Infine ho inviato tutto sul repository remoto:

```bash
git push
```

---

## Risultato finale

L’esercitazione ha permesso di:

* creare e gestire branch differenti;
* lavorare contemporaneamente su più versioni dello stesso progetto;
* generare volontariamente un conflitto durante un merge;
* risolvere il conflitto manualmente tramite terminale;
* completare correttamente il merge e aggiornare il repository remoto.

