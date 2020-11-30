#!/usr/bin/env sh

if [ -n "$VAULT_DEBUG" ]; then
  set -ex
fi

if [ ! -f /vault/config/init.done ]; then
  mkdir -p /dev/shm/vault/config
  echo '{"backend": {"file": {"path": "/vault/file"}}, "listener": {"tcp": {"address": "127.0.0.1:8200", "tls_disable": 1}}}' > /dev/shm/vault/config/config.json
  vault server -config /dev/shm/vault/config &
  export VAULT_ADDR='http://127.0.0.1:8200'
  dockerize -wait tcp://localhost:8200

  if [ -n "$VAULT_INIT_TOKEN" ]; then
    LOGS=$(vault operator init -recovery-shares=1 -recovery-threshold=1)
    UNSEAL_KEY=$(echo "$LOGS" | sed 's/^Recovery Key 1: \(.*\)$/\1/' | head -n 1)
    ROOT_TOKEN=$(echo "$LOGS" | grep 'Initial Root Token' | sed 's/^Initial Root Token: \(.*\)$/\1/')
    export VAULT_TOKEN=$ROOT_TOKEN

    # store these secrets in xdev's vault
    env VAULT_TOKEN=$VAULT_INIT_TOKEN VAULT_ADDR=$VAULT_INIT_URL vault kv put $VAULT_INIT_PATH/vault "unseal=$UNSEAL_KEY" "root=$ROOT_TOKEN"
  else
    LOGS=$(vault operator init -key-shares=1 -key-threshold=1)

    # store the secrets locally so we can automatically restart vault in dev
    echo "$LOGS" > /vault/config/init.log
  fi
  vault operator unseal "$UNSEAL_KEY"
  # configure vault
  vault audit enable file file_path=stdout
  vault secrets enable -version=2 -path=secret kv
  vault secrets enable transit
  vault token create -policy root -id $VAULT_APP_TOKEN
  if [ -f /custom-init.sh ]; then
    . /custom-init.sh
  fi

  # add a file to mark that the init has been done
  touch /vault/config/init.done

  echo "restarting vault with the standard configuration"
  kill %1
  wait %1
fi

if [ -f /vault/config/init.log ]; then
  # the unseal key is available on the disk, lets use it
  vault server -config /vault/config &

  export VAULT_ADDR='http://127.0.0.1:8200'
  UNSEAL_KEY=$(sed 's/^Unseal Key 1: \(.*\)$/\1/' < /vault/config/init.log | head -n 1)
  while ! vault operator unseal "$UNSEAL_KEY"; do
    sleep 1
  done

  wait %1
else
  exec vault server -config /vault/config
fi
