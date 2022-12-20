#!/usr/bin/env sh

set -eu

if test -n "${VAULT_ADDR}"
then
    VAULT_ADDRESS="${VAULT_ADDR#http*://*}"
else
    VAULT_ADDRESS=127.0.0.1:8200
fi

# unlike VAULT_ADDR, that contains the http:// prefix

dockerize -timeout 10s -wait "tcp://${VAULT_ADDRESS}"

echo "Waiting for vault to be initialized"
max_time=10
sleep_time=1
waited_time=0
while ! { wget -O - "http://${VAULT_ADDRESS}/v1/sys/health" 2>& 1 |grep -q '"initialized":true' ; }
do
    if test ${waited_time} -gt ${max_time}
    then
        echo "I already waited ${waited_time}. I won't wait any longer."
        exit 1
    fi
    sleep ${sleep_time}
    waited_time=$(( waited_time + sleep_time ))
done
echo "Vault ready to accept connections"
