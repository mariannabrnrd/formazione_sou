# Esercizio Ansible Vault con `vars_files`

## Obiettivo dell’esercizio

L’obiettivo è imparare a utilizzare **Ansible Vault** per proteggere variabili sensibili all’interno di un file cifrato, includerle in un playbook tramite la direttiva `vars_files` e stampare il loro contenuto a video.

In questo esercizio vengono utilizzati:

* Un file di inventario (`Inventory.yml`)
* Un file contenente variabili cifrate (`secret_vars.yml`)
* Un playbook Ansible (`Playbook.yml`)

---

# 1. Avvio della macchina virtuale

Per prima cosa avviare la macchina virtuale tramite Vagrant.

```bash
vagrant up
```

Verificare che la macchina sia correttamente avviata.

```bash
vagrant status
```

---

# 2. Creazione del file Vault

Per proteggere le variabili sensibili si utilizza **Ansible Vault**.

Creare il file cifrato eseguendo:

```bash
ansible-vault create secret_vars.yml
```

Il comando chiederà di inserire una password.

All’interno del file inserire le variabili nel formato YAML.

Esempio:

```yaml
var_name: esempio
secret: password123
```

Salvare e chiudere il file.

Il contenuto verrà automaticamente cifrato da Ansible.

---

# 3. Configurazione dell’Inventory

Creare il file `Inventory.yml` per definire l’host target.

Struttura utilizzata:

```yaml
all:
  hosts:
    ex-bonus-ansible:
      ansible_host: 192.168.52.10
      ansible.user: vagrant
      ansible_ssh_private_key_file: .vagrant/machines/default/virtualbox/private_key
      ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
```

Questo file permette ad Ansible di collegarsi alla macchina virtuale.

---

# 4. Creazione del Playbook

Nel playbook viene utilizzata la direttiva `vars_files` per importare il file contenente le variabili cifrate.

File `Playbook.yml`:

```yaml
---
- name: Esercizio Ansible Vault con vars_files
  hosts: ex-bonus-ansible
  gather_facts: false

  vars_files:
    - secret_vars.yml

  tasks:
    - name: Stampa il valore delle variabili contenute nel vault
      debug:
        msg: "var_name = {{ var_name }} | secret = {{ secret }}"
```

### Spiegazione delle parti principali

`vars_files` permette di importare variabili definite in file esterni.

```yaml
vars_files:
  - secret_vars.yml
```

Il modulo `debug` stampa a video il contenuto delle variabili.

```yaml
debug:
  msg: "var_name = {{ var_name }} | secret = {{ secret }}"
```

---

# 5. Verifica della connessione

Prima di eseguire il playbook è utile verificare la connessione SSH con Ansible.

```bash
ansible all -i Inventory.yml -m ping
```

Se tutto è corretto verrà restituito:

```text
SUCCESS
```

---

# 6. Esecuzione del Playbook

Poiché il file delle variabili è protetto da Vault, durante l’esecuzione bisogna richiedere la password.

Comando:

```bash
ansible-playbook -i Inventory.yml Playbook.yml --ask-vault-pass
```

Ansible mostrerà il prompt per inserire la password utilizzata durante la creazione del Vault.

---

# 7. Output finale

Se la password è corretta, Ansible eseguirà il task mostrando il contenuto delle variabili.

Esempio di output:

```text
TASK [Stampa il valore delle variabili contenute nel vault]

ok: [ex-bonus-ansible] => {
    "msg": "var_name = esempio | secret = password123"
}
```

---

# Concetti appresi

Con questo esercizio è stato possibile imparare a:

* Creare file cifrati con **Ansible Vault**
* Salvare variabili sensibili in modo sicuro
* Importare file di variabili tramite `vars_files`
* Utilizzare il modulo `debug` per stampare variabili
* Eseguire un playbook richiedendo la password del Vault

---

# Comandi principali utilizzati

Creazione file cifrato:

```bash
ansible-vault create secret_vars.yml
```

Verifica connessione:

```bash
ansible all -i Inventory.yml -m ping
```

Esecuzione playbook con password Vault:

```bash
ansible-playbook -i Inventory.yml Playbook.yml --ask-vault-pass
```

