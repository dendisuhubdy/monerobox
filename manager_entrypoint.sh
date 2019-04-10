#!/bin/bash

set -ex

memLimit_1gb="1508344"
memLimit_2gb="3016688"
memTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`

function update_yml_and_config() {
  git pull

  # copy dockercompose yml files
  cp settings/*.yml /settings
  
  # copy service json only if it does not exist
  if [ ! -f "/settings/service.json" ]; then
    cp settings/service.json /settings/
  else
    echo "service json already exist."
    # add data to service json
  fi
  
  # copy config file according to RAM size of the board, only if it does not exist
  # Monero related service for every model
  if [ ! -f "/settings/monerod.conf" ]; then
    cp settings/monerod.conf /settings
  fi
  
  # Litecoin related service for models with 2GB and 4GB RAM
  if [ "$memTotal" -gt "$memLimit_1gb" ]; then
    if [ ! -f "/settings/litecoind.conf" ]; then
      cp settings/litecoind.conf /settings
    fi
    if [ ! -f "/settings/lnd_ltc.conf" ]; then
      cp settings/lnd_ltc.conf /settings
    fi
    if [ ! -d "/settings/rtl_ltc" ]; then
      mkdir /settings/rtl_ltc
      cp settings/rtl_ltc.conf /settings/rtl_ltc/RTL.conf
    fi
  fi
  
  # Bitcoin related service for models 4GB RAM
  if [ "$memTotal" -gt "$memLimit_2gb" ]; then
    if [ ! -f "/settings/bitcoind.conf" ]; then
      cp settings/bitcoind.conf /settings
    fi
    if [ ! -f "/settings/lnd_btc.conf" ]; then
      cp settings/lnd_btc.conf /settings
    fi
    if [ ! -d "/settings/rtl_btc" ]; then
      mkdir /settings/rtl_btc
      cp settings/rtl_btc.conf /settings/rtl_btc/RTL.conf
    fi
  fi
}

function extra_docker_commands() {
  # create volumes if they don't exist
  docker volume create data_tor
  docker volume create data_monero
  docker volume create data_litecoin
  docker volume create data_bitcoin
  docker volume create data_lnd_ltc
  docker volume create data_lnd_btc
}

function update_docker_images() {
  # pull and start optional docker images
  enabled=$(jq '.monero.enabled' /settings/service.json)
  if [ "$enabled" = "true" ]; then
    /usr/local/bin/docker-compose -f /settings/monero.yml pull
    /usr/local/bin/docker-compose -f /settings/monero.yml up -d
  fi
  enabled=$(jq '.litecoin.enabled' /settings/service.json)
  if [ "$enabled" = "true" ]; then
    /usr/local/bin/docker-compose -f /settings/litecoin.yml pull
    /usr/local/bin/docker-compose -f /settings/litecoin.yml up -d
  fi
  enabled=$(jq '.bitcoin.enabled' /settings/service.json)
  if [ "$enabled" = "true" ]; then
    /usr/local/bin/docker-compose -f /settings/bitcoin.yml pull
    /usr/local/bin/docker-compose -f /settings/bitcoin.yml up -d
  fi

  # pull and start mandatory docker images
  /usr/local/bin/docker-compose -f /settings/monerobox.yml pull
  /usr/local/bin/docker-compose -f /settings/monerobox.yml up -d tor
  /usr/local/bin/docker-compose -f /settings/monerobox.yml up -d web
  # manager container does not start itself, this is done by web container
}

cd /usr/src/app/monerobox

while :
do
  update_yml_and_config

  extra_docker_commands

  update_docker_images

  # check for update every 12 hours
  sleep 12h
done

