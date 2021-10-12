#!/bin/bash

set -x

VAULT_ADDRESS=localhost:8200
# unlike VAULT_ADDR, that contains the http:// prefix

dockerize -wait "tcp://${VAULT_ADDRESS}"

echo "Waiting for vault to be initialized"
while ! { wget -O - "http://${VAULT_ADDRESS}/v1/sys/health" 2>& 1 |grep -q '"initialized":true' ; }
do
    sleep 1
done
echo "Vault ready to accept connections"
