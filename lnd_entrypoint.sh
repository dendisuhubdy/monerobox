#!/bin/bash

if [ "$1" = "bitcoin" ]; then
  echo "Starting lnd for Bitcoin"
  configFile="--configfile=/settings/lnd_btc.conf"
elif [ "$1" = "litecoin" ]; then
  echo "Starting lnd for Litecoin"
  configFile="--configfile=/settings/lnd_ltc.conf"
else
  echo "Unknown coin type: $1, exiting..."
  exit 1
fi

# read service.json
tor=$(jq '.litecoin.tor' /settings/service.json)
if [ "$tor" = "true" ]; then
  echo "lnd will use tor."

  sleep 10;
  tor_ip=$(getent hosts tor | awk '{ print $1 }')

  if [ -z "$tor_ip" ]; then
    echo "ERROR: Unable to find IP of tor service!";
    exit 1;
  fi

  proxy="$tor_ip:9050"
else
  echo "lnd will NOT use tor."
fi

exec /usr/src/app/lnd $configFile $proxy
