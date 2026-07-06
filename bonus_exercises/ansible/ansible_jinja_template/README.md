# Esercizio Ansible con Template Jinja

## Obiettivo dell'esercizio

L'obiettivo è imparare a utilizzare i **template Jinja** all'interno dei playbook Ansible per generare file in modo dinamico. Grazie a variabili, condizioni (`if`) e cicli (`for`), è possibile creare configurazioni differenti in base all'ambiente di esecuzione o ai dati forniti dal playbook, automatizzando così la gestione dei file di configurazione.

---

# 1. Avvio della macchina virtuale

Avviare la macchina virtuale con Vagrant.

```bash
vagrant up
```

Verificare che sia in esecuzione.

```bash
vagrant status
```

---

# 2. Verifica della connessione

Prima di eseguire i playbook è consigliabile verificare la connessione con Ansible.

```bash
ansible all -i Inventory.yml -m ping
```

Se la configurazione è corretta verrà restituito:

```text
SUCCESS
```

---

# 3. Primo esercizio - Configurazione di `/etc/security/limits.conf`

In questo esercizio viene utilizzato un **template Jinja** per generare automaticamente il contenuto da aggiungere al file `/etc/security/limits.conf`.

Il template contiene una struttura condizionale (`if` / `elif`) che imposta valori differenti in base alla variabile `env`.

```jinja
{% if env == 'production' %}
* hard nofile 10000
* soft nofile 10000
{% elif env == 'staging' or env == 'development' %}
* hard nofile 1000
* soft nofile 1000
{% endif %}
```

Se l'ambiente è **production**, vengono impostati i limiti a **10000** file aperti; se invece l'ambiente è **staging** o **development**, il limite viene impostato a **1000**.

---

## Come funziona il playbook

Il primo task utilizza il modulo `template` per generare un file temporaneo partendo dal template Jinja.

```bash
ansible.builtin.template:
  src: limits.conf.j2
  dest: /tmp/output.txt
```

Successivamente il modulo `blockinfile` legge il contenuto del file appena creato e lo aggiunge in fondo al file `/etc/security/limits.conf`.

```bash
ansible.builtin.blockinfile:
  path: /etc/security/limits.conf
  block: "{{ lookup('ansible.builtin.file', '/tmp/output.txt') }}"
  insertafter: EOF
  create: yes
```

L'opzione `insertafter: EOF` indica ad Ansible di inserire il blocco alla fine del file.

---

## Esecuzione del playbook

La variabile `env` viene passata da riga di comando tramite `--extra-vars`.

```bash
ansible-playbook -i Inventory.yml Playbook_1.yml --extra-vars "env=development"
```

È possibile sostituire `development` con `staging` oppure `production`.

---

## Verifica del risultato

Per controllare le ultime righe del file modificato:

```bash
ansible -i Inventory.yml all -m command -a "tail -5 /etc/security/limits.conf"
```

---

# 4. Secondo esercizio - Gestione della whitelist in `/etc/security/access.conf`

Prima di eseguire il playbook viene creato il file `access.conf` contenente la regola finale che blocca tutti gli utenti non autorizzati.

```bash
ansible -i Inventory.yml all -m lineinfile -a "path=/etc/security/access.conf line='- : ALL : ALL' create=yes" --become
```

---

## Il template Jinja

Per questo esercizio viene utilizzato un ciclo `for` che genera automaticamente una riga per ogni utente presente nella lista.

```jinja
{% for user in users %}
+ : {{ user }} : ALL
{% endfor %}
```

Ogni elemento della lista produce una riga nel file di output.

---

## Come funziona il playbook

Nel playbook è definita una lista di utenti.

```bash
vars:
  users:
    - mario
    - giulia
    - luigi
```

Il modulo `template` genera il file temporaneo.

```bash
ansible.builtin.template:
  src: access.conf.j2
  dest: /tmp/output.txt
```

Successivamente il modulo `blockinfile` inserisce il blocco **prima** della regola finale che nega l'accesso a tutti gli utenti.

```bash
ansible.builtin.blockinfile:
  path: /etc/security/access.conf
  block: "{{ lookup('ansible.builtin.file', '/tmp/output.txt') }}"
  insertbefore: '- : ALL : ALL'
  create: yes
```

L'opzione `insertbefore` permette di inserire il blocco immediatamente prima della riga indicata.

---

## Esecuzione del playbook

```bash
ansible-playbook -i Inventory.yml Playbook_2.yml
```

---

## Verifica del risultato

Per visualizzare il contenuto del file modificato:

```bash
ansible -i Inventory.yml all -m command -a "cat /etc/security/access.conf"
```

L'output mostrerà gli utenti autorizzati inseriti prima della regola finale:

```text
+ : mario : ALL
+ : giulia : ALL
+ : luigi : ALL
- : ALL : ALL
```

---

# Concetti appresi

Con questo esercizio è stato possibile imparare a:

* utilizzare i template **Jinja** all'interno dei playbook Ansible;
* utilizzare strutture condizionali (`if` / `elif`) nei template;
* utilizzare cicli (`for`) per generare contenuti ripetitivi;
* passare variabili al playbook tramite `--extra-vars`;
* generare file temporanei con il modulo `template`;
* modificare file di configurazione con il modulo `blockinfile`;
* inserire blocchi di testo alla fine di un file (`insertafter`) oppure prima di una riga specifica (`insertbefore`).

