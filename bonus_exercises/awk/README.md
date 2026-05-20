# Esercizio AWK e alternative con grep + sed

## Contesto

Scrivere un programma AWK che prende in input un file .csv e stampa il terzo campo solo se viene matchata la stringa "banana".

---

## Utilizzo di AWK

### Comando

```bash
awk -F',' '/banana/ {print $3}' file.csv
```

### Output

```text
strawberry
orange
```

### Spiegazione

* `-F','` → imposta la virgola come delimitatore di campo
* `/banana/` → filtra le righe che contengono "banana"
* `{print $3}` → stampa il terzo campo delle righe filtrate

---

## Alternativa con grep e sed

### Comando

```bash
grep "banana" file.csv | sed 's/\([^,]*,\)\{2\}\([^,]*\).*/\2/'
```

### Output

```text
strawberry
orange
```

### Spiegazione

* `grep "banana"` → seleziona le righe contenenti "banana"
* `sed` → estrae il terzo campo tramite espressioni regolari

#### Dettaglio dell'espressione `sed`

* `\([^,]*,\)\{2\}` → salta i primi due campi
* `\([^,]*\)` → cattura il terzo campo
* `.*` → ignora il resto della riga
* `\2` → restituisce il contenuto del gruppo catturato
