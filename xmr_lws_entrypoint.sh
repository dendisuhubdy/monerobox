#!/bin/bash

exec /usr/src/app/monero-light-wallet-server --db-path=/data/monero/light_wallet_server --daemon=tcp://172.20.1.10:18082 --rest-server=http://172.20.1.11:8080 --confirm-external-bind --log-level=4
