#/bin/bash

docker network create --subnet 172.20.1.0/24 --gateway 172.20.1.1 monerobox
docker volume create settings
docker volume create data_tor
docker volume create data_monero
docker volume create data_litecoin
docker volume create data_bitcoin
docker volume create data_lnd_ltc
docker volume create data_lnd_btc

export HOST_HOSTNAME=$(hostname)
export HOST_IP=$(ip -4 addr show eth0 | grep -Po 'inet \K[\d.]+')

docker-compose -f settings/monerobox.yml pull
docker-compose -f settings/monerobox.yml up -d manager

