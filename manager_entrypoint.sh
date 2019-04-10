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
    echo "copy monero related config file"
  fi
  
  # Litecoin related service for models with 2GB and 4GB RAM
  if [ "$memTotal" -gt "$memLimit_1gb" ]; then
    if [ ! -f "/settings/litecoind.conf" ]; then
      echo "copy litecoin related config file"
    fi
  fi
  
  # Bitcoin related service for models 4GB RAM
  if [ "$memTotal" -gt "$memLimit_2gb" ]; then
    if [ ! -f "/settings/bitcoind.conf" ]; then
      echo "copy bitcoin related config file"
    fi
  fi
}

function extra_docker_commands() {
  # extra commands such as create volume
  echo "extra docker commands"
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
    /usr/local/bin/docker-compose -f /settings/monero.yml up -d
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

