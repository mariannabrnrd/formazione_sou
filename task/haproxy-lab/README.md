# HAProxy Lab — Deploy su VM

Esercizio pratico di deploy di HAProxy su una VM Debian con due interfacce di rete appartenenti a due subnet diverse, configurando routing, firewall e proxy.

---

## Architettura

```
HOST (Mac)
    │
    ├── eth1 → 192.168.56.10  (subnet client)
    │               │
    │           HAProxy VM
    │               │
    └── eth2 → 192.168.57.10  (subnet backend)
                    │
          ┌─────────┴─────────┐
          │                   │
    192.168.57.11        192.168.57.12
      (backend 1)          (backend 2)
```

La VM utilizza tre interfacce di rete:
- **eth0** — gestita da Vagrant, usata per SSH e accesso a internet
- **eth1** — subnet client (`192.168.56.0/24`), su cui HAProxy ascolta le richieste
- **eth2** — subnet backend (`192.168.57.0/24`), su cui HAProxy contatta i server reali

### Requisiti

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/)

---

# 1. Creazione della VM

### Vagrantfile

Il `Vagrantfile` crea una VM Debian e aggiunge **due reti private**, che diventeranno le interfacce `eth1` ed `eth2`.

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "haproxy-vm"

  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "private_network", ip: "192.168.57.10"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "haproxy-vm"
    vb.memory = "1024"
    vb.cpus = 1
  end
end
```

### Perché due `private_network`?

Ogni riga crea una **scheda di rete virtuale** collegata ad una subnet diversa.

- **192.168.56.10** → rete dei client (`eth1`)
- **192.168.57.10** → rete dei backend (`eth2`)

In questo modo HAProxy può ricevere richieste da una rete e comunicare con i server sull'altra.

### Avvio della VM

```bash
vagrant up
vagrant ssh
```
---

# 2. Verifica delle interfacce

Dopo l'avvio della VM verifichiamo che le interfacce siano state create correttamente.

```bash
ip addr
```

Output semplificato:

```text
eth0 → 10.0.2.15/24
eth1 → 192.168.56.10/24
eth2 → 192.168.57.10/24
```

## Spiegazione

| Interfaccia | Funzione |
|---|---|
| **eth0** | Rete NAT di Vagrant, usata per SSH e Internet |
| **eth1** | Subnet `192.168.56.0/24`, lato client |
| **eth2** | Subnet `192.168.57.0/24`, lato backend |

Ogni interfaccia ha un proprio indirizzo IP e appartiene ad una subnet diversa.

---

# 3. Analisi della routing table

Prima di configurare il routing controlliamo la tabella principale di Linux.

```bash
ip route
```

Output:

```text
default via 10.0.2.2 dev eth0
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15
192.168.56.0/24 dev eth1 proto kernel scope link src 192.168.56.10
192.168.57.0/24 dev eth2 proto kernel scope link src 192.168.57.10
```

## Spiegazione della routing table

| Riga | Significato |
|---|---|
| `default via 10.0.2.2 dev eth0` | È la **default route**: tutto il traffico destinato a reti sconosciute passa dal gateway di Vagrant. |
| `10.0.2.0/24 dev eth0` | È la rete NAT creata automaticamente da Vagrant. |
| `192.168.56.0/24 dev eth1` | È la subnet dei client, collegata direttamente a `eth1`. |
| `192.168.57.0/24 dev eth2` | È la subnet dei backend, collegata direttamente a `eth2`. |

In pratica Linux confronta la destinazione del pacchetto con questa tabella e sceglie automaticamente l'interfaccia da utilizzare.

---

# 4. Policy Routing

Con due interfacce di rete può verificarsi un problema: una richiesta entra da `eth2`, ma Linux potrebbe inviare la risposta usando un'interfaccia diversa.

Per evitare questo comportamento creiamo una **seconda routing table** dedicata alla rete backend.

## Creazione della tabella

Registriamo una nuova tabella chiamata `backend_rt` con ID **200**.

```bash
echo "200 backend_rt" | sudo tee -a /etc/iproute2/rt_tables
```

## Aggiunta della rotta

```bash
sudo ip route add 192.168.57.0/24 dev eth2 table backend_rt
```

Questa tabella conosce la rete backend e utilizza sempre `eth2`.

## Aggiunta della regola

```bash
sudo ip rule add from 192.168.57.10 table backend_rt priority 100
```

La regola dice al kernel:

> Se un pacchetto ha come indirizzo sorgente `192.168.57.10`, utilizza la tabella `backend_rt`.

## Verifica

```bash
ip rule show
ip route show table backend_rt
```

Output:

```text
0:      from all lookup local
100:    from 192.168.57.10 lookup backend_rt
32766:  from all lookup main
32767:  from all lookup default
```

Il numero a sinistra rappresenta la **priorità**: più è basso, prima viene controllata la regola.

## Persistenza

Le regole create con `ip route` e `ip rule` sono temporanee e vengono perse al riavvio.

Creiamo quindi uno script eseguito automaticamente quando le interfacce vengono attivate.

`/etc/network/if-up.d/policy-routing`

```bash
#!/bin/sh

ip route add 192.168.57.0/24 dev eth2 table backend_rt
ip rule add from 192.168.57.10 table backend_rt priority 100
```

Renderlo eseguibile:

```bash
sudo chmod +x /etc/network/if-up.d/policy-routing
```

---

## 5. Installazione HAProxy

```bash
sudo apt update && sudo apt install -y haproxy
sudo systemctl enable haproxy
```

### verifica:

```bash
haproxy -v
systemctl status haproxy
```

---
# 6. Configurazione di HAProxy

File di configurazione:

```text
/etc/haproxy/haproxy.cfg
```

Sono state aggiunte le sezioni `frontend`, `backend` e `listen`.

```cfg
frontend fe_http
    bind 192.168.56.10:80
    default_backend be_web
    option forwardfor

backend be_web
    balance roundrobin
    option httpchk GET /
    server web1 192.168.57.11:80 check
    server web2 192.168.57.12:80 check

listen stats
    bind 192.168.56.10:8404
    stats enable
    stats uri /stats
    stats auth admin:password123
```

## Spiegazione

### Frontend

È la parte visibile ai client.

- **bind 192.168.56.10:80** → HAProxy ascolta sulla rete client (`eth1`) sulla porta 80.
- **default_backend be_web** → tutte le richieste vengono inviate al backend.
- **option forwardfor** → aggiunge l'header `X-Forwarded-For` con l'IP reale del client.

### Backend

Contiene i server reali.

- **balance roundrobin** → distribuisce le richieste in modo alternato tra i backend.
- **option httpchk GET /** → controlla periodicamente che i server siano raggiungibili.
- **check** → abilita il controllo sul singolo server.

### Statistiche

La pagina di monitoraggio è disponibile su:

```text
http://192.168.56.10:8404/stats
```

ed è protetta da username e password.

## Verifica della configurazione

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl restart haproxy
sudo systemctl status haproxy
```

---

# 7. Firewall con nftables

Il firewall deve permettere soltanto il traffico necessario.

| Interfaccia | Porta | Utilizzo |
|---|---|---|
| **eth0** | 22 | SSH |
| **eth1** | 80 | Frontend HAProxy |
| **eth1** | 8404 | Pagina statistiche |

Modifichiamo il file:

```text
/etc/nftables.conf
```

```nft
#!/usr/sbin/nft -f

flush ruleset

table inet filter {

    chain input {
        type filter hook input priority filter; policy drop;

        ct state established,related accept
        iif lo accept

        iif eth0 tcp dport 22 accept
        iif eth1 tcp dport 80 accept
        iif eth1 tcp dport 8404 accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
```

## Spiegazione

- **flush ruleset** → elimina eventuali regole già presenti.
- **policy drop** → tutto il traffico viene bloccato per default.
- **established,related** → permette le connessioni già aperte.
- **iif lo** → permette la comunicazione interna della VM.
- **porta 22** → mantiene l'accesso SSH.
- **porta 80** → permette ai client di raggiungere HAProxy.
- **porta 8404** → abilita la pagina delle statistiche.

## Applicazione

Verifica della sintassi:

```bash
sudo nft -c -f /etc/nftables.conf
```

Applichiamo le regole:

```bash
sudo nft -f /etc/nftables.conf
```

Verifica:

```bash
sudo nft list ruleset
```

## Persistenza

Su Debian è sufficiente abilitare il servizio:

```bash
sudo systemctl enable nftables
sudo systemctl start nftables
sudo systemctl status nftables
```
---

## Verifica finale

```bash
# Routing table principale
ip route show

# Policy routing
ip rule show
ip route show table backend_rt

# Firewall
sudo nft list ruleset

# HAProxy
sudo systemctl status haproxy

# Test del proxy
curl http://192.168.56.10
```

---

## Test con backend simulati

In assenza di VM backend reali, è possibile simulare due server web sulla stessa VM usando Python:

```bash
# Terminale 1
sudo python3 -m http.server 8081 --bind 127.0.0.1

# Terminale 2
sudo python3 -m http.server 8082 --bind 127.0.0.1
```

Modificare temporaneamente `/etc/haproxy/haproxy.cfg`:
```
server web1 127.0.0.1:8081 check
server web2 127.0.0.1:8082 check
```

Poi testare il bilanciamento:
```bash
curl http://192.168.56.10
```

Le richieste vengono distribuite in alternanza tra i due server — il roundrobin funziona.

---

## Concetti chiave

| Concetto | Descrizione |
|---|---|
| **Proxy** | Intermediario che stabilisce due connessioni separate — una col client e una col backend. Diverso dal router che smista pacchetti senza aprirli. |
| **Routing table** | Tabella consultata dal kernel per decidere da quale interfaccia far uscire ogni pacchetto. |
| **Policy routing** | Tecnica che permette di usare routing table diverse in base a criteri specifici, come l'indirizzo sorgente del pacchetto. |
| **Asymmetric routing** | Problema che nasce con due NIC — la risposta esce da un'interfaccia diversa da quella da cui è arrivata la richiesta, rompendo le connessioni TCP. |
| **nftables** | Strumento Linux per la gestione del firewall a livello kernel. Le regole sono organizzate in tabelle e catene. |
| **Roundrobin** | Algoritmo di bilanciamento che distribuisce le richieste in modo alternato tra i backend disponibili. |
| **Health check** | Controllo periodico che HAProxy fa sui backend per verificare che siano attivi. Se un backend non risponde, viene escluso automaticamente. |
