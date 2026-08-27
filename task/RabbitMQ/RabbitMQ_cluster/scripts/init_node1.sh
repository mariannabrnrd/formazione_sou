#!/bin/bash
set -e

echo ">>> Copio la Erlang cookie in /vagrant per condividerla"
cp /var/lib/rabbitmq/.erlang.cookie /vagrant/.erlang.cookie
chmod 644 /vagrant/.erlang.cookie

echo ">>> Importo le definizioni (utenti, permessi, vhost)"
sleep 5 #aspetto che RabbitMQ sia pronto
rabbitmqctl import_definitions /vagrant/rabbitmq-definitions.json

echo ">>> Node1 pronto!"