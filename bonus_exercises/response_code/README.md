# Simulazione HTTP Response Code con Apache

## Avvio Apache Server sulla VM1

Avvio del servizio:

```bash
sudo systemctl start apache2
```

Controllo che sia attivo:

```bash
sudo systemctl status apache2
```

---

## Test della connessione dalla VM2

Dalla seconda VM eseguiamo una richiesta HTTP verso la VM1:

```bash
curl http://<indirizzo_ip>
```

In questo modo:

- VM2 agisce come client HTTP
- Apache sulla VM1 agisce come server HTTP

Se vogliamo visualizzare solo gli header HTTP:

```bash
curl -I http://<indirizzo_ip>
```

La flag `-I` mostra solamente gli header della risposta HTTP.

---

# RESPONSE CODE 302

Nel mio caso inizialmente il response code era:

```http
302 Found
```

![Response Code 302](output/response%20code%20302.png)

Questo perchè il file di configurazione Apache era già configurato per effettuare un redirect sulla porta `80` alla porta `443` (HTTPS).

Quindi:

- la risposta arrivava sulla porta 80
- Apache rispondeva con un redirect temporaneo verso HTTPS

---

## VirtualHost fallback

Avendo un solo VirtualHost configurato, Apache lo utilizza automaticamente come fallback/default host.

Quindi, anche se la richiesta non corrispondeva perfettamente a un dominio specifico:

- Apache utilizza comunque quel VirtualHost
- purchè sia l'unico disponibile

---

## Creazione di un nuovo VirtualHost

Ho creato un nuovo file di configurazione -> `simulazione.conf`

Configurazione:

```apache
<VirtualHost *:80>
    ServerName simulazione.local
    ServerAlias 192.168.3.167
    DocumentRoot /var/www/simulazione
</VirtualHost>
```

Questo VirtualHost:

- ascolta sulla porta 80
- risponde per `simulazione.local`
- usa `/var/www/simulazione` come root del sito

---

## Configurazione del file hosts

Per fare in modo che VM2 riconosca `simulazione.local` ho modificato il file:

```bash
sudo vim /etc/hosts
```

Aggiungendo:

```bash
<indirizzo_ip> simulazione.local
```

In questo modo:

- VM2 associa manualmente il dominio all'indirizzo IP
- senza utilizzare DNS esterni

---

## Test del VirtualHost

Dalla VM2:

```bash
curl -I https://simulazione.local
```

A questo punto il server restituisce:

```http
200 OK
```

![Response Code 200](output/response%20code%20200.png)

---

# Caso particolare: Directory Listing

Inizialmente la richiesta era diretta solamente alla directory:

```bash
/var/www/simulazione
```

Normalmente, in molte configurazioni Apache, questo potrebbe produrre:

```http
403 Forbidden
```

Perchè:

- stiamo richiedendo una directory
- non un file specifico
- Apache potrebbe impedire la visualizzazione del contenuto

Nel mio caso invece Apache aveva il **directory listing** abilitato.

Quindi:

- legge il contenuto della directory
- genera automaticamente una pagina HTML
- mostra l'elenco delle risorse presenti

---

## File index.html

Successivamente ho creato un file -> `index.html`

Nel percorso:

```bash
/var/www/simulazione
```

Da questo momento Apache:

- trova automaticamente `index.html`
- lo restituisce come pagina principale del sito

Questo cambia l'output perchè:

- non viene più mostrato il directory listing
- viene servito direttamente il file index

![Response Code 200 con index](output/response%20code%20200%20con%20index.png)

---

# RESPONSE CODE 401

Per simulare:

```http
401 Unauthorized
```

ho configurato autenticazione HTTP Basic.

---

## Creazione utente/password

```bash
sudo htpasswd -c /etc/apache2/.htpasswd <nome_utente>
```

La flag `-c` crea il file.

Successivamente Apache richiede la password dell'utente.

---

## Configurazione protezione directory

Nel file di configurazione Apache:

```apache
<Directory /var/www/simulazione/privata>
    AuthType Basic
    AuthName "Area riservata"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Directory>
```

Ho creato inoltre la directory:

```bash
/var/www/simulazione/privata
```

che contiene le risorse protette.

---

## Test autenticazione

Sia se facciamo una richiesta senza credenziali:

```bash
curl -I http://simulazione.local/privata
```

Sia che mettiamo le credenziali sbagliate:

```bash
curl -I -u nomeutente:password_sbagliata http://simulazione.local/privata
```

Apache restituisce:

```http
401 Unauthorized
```

![Response Code 401](output/response%20code%20401.png)

---

# CASO 301 REDIRECT

Quando ho usato:

```bash
curl -I -u nomeutente:password http://simulazione.local/privata
```

Apache ha restituito:

```http
301 Permanently
```

Questo succede perchè:

- `privata` è una directory
- manca lo slash finale
- Apache effettua automaticamente un redirect verso `/privata/`
- per normalizzare il percorso

---

## Percorso corretto

Utilizzando il percorso corretto:

```bash
curl -I -u nomeutente:password http://simulazione.local/privata/
```

Apache restituisce:

```http
200 OK
```

Perchè:

- autenticazione corretta
- directory accessibile
- richiesta valida

![Response Code 301-200](output/response%20code%20301-200.png)

---

# RESPONSE CODE 500

Per simulare:

```http
500 Internal Server Error
```

ho creato uno script CGI volutamente errato.

---

## Script CGI

Uno script CGI permette ad Apache di:

- eseguire programmi/script
- inviare il loro output come risposta HTTP

Uno script CGI valido deve restituire correttamente gli header HTTP.

---

## Script CGI rotto

```bash
#!/bin/bash
echo "questo script è rotto"
exit 1
```

Problemi dello script:

- manca un header HTTP valido
- termina con `exit 1`
- Apache interpreta l'esecuzione come fallita

Di conseguenza Apache genera:

```http
500 Internal Server Error
```

---

## Abilitazione modulo CGI

Ho abilitato il modulo CGI:

```bash
sudo a2enmod cgi
```

---

## Configurazione Apache

```apache
<Directory /var/www/simulazione/errore500>
    Options +ExecCGI
    AddHandler cgi-script .sh
</Directory>
```

Questa configurazione:

- abilita esecuzione CGI
- tratta i file `.sh` come script CGI

---

## Risultato finale

Dopo la configurazione:

- Apache esegue lo script
- lo script fallisce
- Apache restituisce:

```http
500 Internal Server Error
```

![Response Code 500](output/response%20code%20500.png)

