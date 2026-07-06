# Esercizio Ansible con Liste e Dizionari

## Obiettivo dell'esercizio

L'obiettivo è imparare a utilizzare le **strutture dati complesse** di Ansible, come **liste** e **dizionari**, all'interno dei playbook. In particolare, l'esercizio mostra come automatizzare la gestione dei pacchetti e la creazione degli utenti utilizzando variabili strutturate e cicli (`loop`).

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

Prima di eseguire i playbook è consigliabile verificare la connessione alla macchina.

```bash
ansible all -i Inventory.yml -m ping
```

Se tutto è configurato correttamente verrà restituito:

```text
SUCCESS
```

---

# 3. Playbook per la gestione dei pacchetti

Il primo playbook utilizza un **dizionario** per definire lo stato desiderato dei pacchetti.

Esempio:

```yaml
vars:
  packages:
    vim: present
    curl: present
    htop: present
    nano: absent
```

Ogni chiave rappresenta il nome del pacchetto, mentre il valore indica se deve essere installato (`present`) oppure rimosso (`absent`).

Per elaborare il dizionario viene utilizzato un ciclo con `loop` e il filtro `dict2items`, che converte il dizionario in una lista di elementi.

```yaml
loop: "{{ packages | dict2items }}"
```

Il modulo `package` installa o rimuove automaticamente ogni pacchetto in base allo stato specificato.

---

# 4. Esecuzione del playbook dei pacchetti

Eseguire il playbook con il comando:

```bash
ansible-playbook -i Inventory.yml Playbook1_packages.yml
```

---

# 5. Playbook per la creazione degli utenti

Il secondo playbook utilizza una **lista di dizionari**, nella quale ogni elemento rappresenta un utente con le proprie caratteristiche.

Esempio:

```yaml
vars:
  users:
    - name: mario
      group: developers
      shell: /bin/bash
      home: /home/mario

    - name: giulia
      group: admins
      shell: /bin/zsh
      home: /home/giulia
```

Per ogni elemento della lista vengono eseguite due operazioni:

* creazione del gruppo;
* creazione dell'utente con gruppo, shell e home directory specificati.

Entrambe le operazioni vengono eseguite tramite un ciclo:

```yaml
loop: "{{ users }}"
```

---

# 6. Esecuzione del playbook degli utenti

Eseguire il playbook con il comando:

```bash
ansible-playbook -i Inventory.yml Playbook2_users.yml
```

---

# Concetti appresi

Con questo esercizio è stato possibile imparare a:

* utilizzare dizionari per gestire configurazioni;
* utilizzare liste di dizionari per rappresentare oggetti complessi;
* eseguire operazioni ripetitive tramite `loop`;
* convertire un dizionario in una lista con `dict2items`;
* automatizzare l'installazione/rimozione dei pacchetti;
* creare utenti e gruppi tramite Ansible.
