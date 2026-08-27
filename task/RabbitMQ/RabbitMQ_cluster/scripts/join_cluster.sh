#!/bin/bash
set -e

echo ">>> Sincronizzo Erlang cookie da node1"
systemctl stop rabbitmq-server

#Prendo la cookie che node1 ha salvato in /vagrant
cp /vagrant/.erlang.cookie /var/lib/rabbitmq/.erlang.cookie
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 400 /var/lib/rabbitmq/.erlang.cookie

#Pulisco i dati precedenti
rm -rf /var/lib/rabbitmq/mnesia/

systemctl start rabbitmq-server
sleep 5

echo ">>> Verifico stato cluster"
rabbitmqctl stop_app
rabbitmqctl reset
rabbitmqctl join_cluster rabbit@rabbitmq-node1
rabbitmqctl start_app

echo ">>> Verifico stato cluster"
rabbitmqctl cluster_status

echo ">>> Nodo aggiunto al cluster!"