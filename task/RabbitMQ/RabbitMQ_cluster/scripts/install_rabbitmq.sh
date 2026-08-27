#!/bin/bash
set -e

echo ">>> Aggiorno il sistema"
apt-get update -qq && apt-get upgrade -y -qq

echo ">>> Installo dipendenze"
apt-get install -y curl gnupg apt-transport-https

echo ">>> Aggiungo repo Erlang"
curl -1sLf 'https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/setup.deb.sh' | bash

echo ">>> Aggiungo repo RabbitMQ"
apt-get install -y erlang rabbitmq-server

echo ">>> Configuro /etc/hosts"
cat >> /etc/hosts << EOF
192.168.56.11 rabbitmq-node1
192.168.56.12 rabbitmq-node2
192.168.56.13 rabbitmq-node3
EOF

echo ">>> Abilito e avvio RabbitMQ"
systemctl enable rabbitmq-server
systemctl start rabbitmq-server

echo ">>> Installo managment plugin"
rabbitmq-plugins enable rabbitmq_management