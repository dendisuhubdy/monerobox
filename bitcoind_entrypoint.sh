#!/bin/bash

# read service.json
tor=$(jq '.bitcoin.tor' /settings/service.json)

if [ "$tor" = "true" ]; then
  echo "bitcoind will use tor."

  sleep 10;
  tor_ip=$(getent hosts tor | awk '{ print $1 }')

  if [ -z "$tor_ip" ]; then
    echo "ERROR: Unable to find IP of tor service!";
    exit 1;
  fi

  proxy="$tor_ip:9050"
else
  echo "bitcoind will NOT use tor."
fi

exec $@ $proxy
