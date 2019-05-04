#!/bin/bash

set -ex

memLimit_1gb="1508344"
memLimit_2gb="3016688"
memTotal=`grep MemTotal /proc/meminfo | awk '{print $2}'`

function update_monerobox() {
  # copy dockercompose yml files
  cp settings/monerobox.yml /settings

  # copy service json only if it does not exist
  if [ ! -f "/settings/service.json" ]; then
    cp settings/service.json /settings/
  else
    echo "service json already exist."
    # add data to service json
  fi

  # copy tor config file only if it does not exist
  if [ ! -f "/settings/tor.conf" ]; then
    cp settings/tor.conf /settings/
  else
    echo "tor config already exist."
    # add data to tor config
  fi

  # copy stunnel config file only if it does not exist
  if [ ! -f "/settings/stunnel.conf" ]; then
    cp settings/stunnel.conf /settings/
  else
    echo "stunnel config already exist."
    # add data to stunnel config
  fi

  # create volume if they do not exist
  docker volume create data_tor

  # pull and start mandatory docker images
  /usr/local/bin/docker-compose -f /settings/monerobox.yml pull
  /usr/local/bin/docker-compose -f /settings/monerobox.yml up -d tor
  /usr/local/bin/docker-compose -f /settings/monerobox.yml up -d web
  # manager container does not start itself, this is done by web container
}

function update_monero() {
  # copy dockercompose yml files
  cp settings/monero.yml /settings

  # copy config file
  if [ ! -f "/settings/monerod.conf" ]; then
    cp settings/monerod.conf /settings
  fi

  # create volume if they do not exist
  docker volume create data_monero

  # pull and start optional docker images
  enabled=$(jq '.monero.enabled' /settings/service.json)
  if [ "$enabled" = "true" ]; then
    /usr/local/bin/docker-compose -f /settings/monero.yml pull
    /usr/local/bin/docker-compose -f /settings/monero.yml up -d
  fi
}


function update_litecoin() {
  # Litecoin related service for models with 2GB and 4GB RAM
  if [ "$memTotal" -gt "$memLimit_1gb" ]; then
    # copy dockercompose yml files
    cp settings/litecoin.yml /settings

    # copy config file
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

    # create volumes if they don't exist
    docker volume create data_litecoin
    docker volume create data_lnd_ltc

    # pull and start optional docker images
    enabled=$(jq '.litecoin.enabled' /settings/service.json)
    if [ "$enabled" = "true" ]; then
      /usr/local/bin/docker-compose -f /settings/litecoin.yml pull
      /usr/local/bin/docker-compose -f /settings/litecoin.yml up -d
    fi
  fi
}

function update_bitcoin() {
  # Bitcoin related service for models 4GB RAM
  if [ "$memTotal" -gt "$memLimit_2gb" ]; then
    # copy dockercompose yml files
    cp settings/bitcoin.yml /settings

    # copy config files
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

    # create volumes if they don't exist
    docker volume create data_bitcoin
    docker volume create data_lnd_btc

    # pull and start optional docker images
    enabled=$(jq '.bitcoin.enabled' /settings/service.json)
    if [ "$enabled" = "true" ]; then
      /usr/local/bin/docker-compose -f /settings/bitcoin.yml pull
      /usr/local/bin/docker-compose -f /settings/bitcoin.yml up -d
    fi

  fi
}


cd /usr/src/app/monerobox
git pull

update_monerobox
update_monero
update_litecoin
update_bitcoin

exit
