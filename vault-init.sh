#!/usr/bin/env sh

# make sure to stop if any of the command run in this script fail
set -e
if [ "$VAULT_DEBUG" == "true" ]; then
  set -x
fi

if [ ! -f /vault/file/init.done ]; then
  mkdir -p /dev/shm/vault/config
  cp -r /vault/config/* /dev/shm/vault/config/
  if [ -z "$(ls -A /extra/config)" ]; then
    cp -r /extra/config/* /dev/shm/vault/config/
  fi
  cp /listener-init.hcl /dev/shm/vault/config/listener.hcl
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
    UNSEAL_KEY=$(echo "$LOGS" | sed 's/^Unseal Key 1: \(.*\)$/\1/' | head -n 1)
    ROOT_TOKEN=$(echo "$LOGS" | grep 'Initial Root Token' | sed 's/^Initial Root Token: \(.*\)$/\1/')
    export VAULT_TOKEN=$ROOT_TOKEN

    # store the secrets locally so we can automatically restart vault in dev
    echo "$LOGS" > /vault/file/init.log
  fi
  vault operator unseal "$UNSEAL_KEY"
  # configure vault
  vault audit enable file file_path=stdout
  vault secrets enable -version=2 -path=secret kv
  vault secrets enable transit
  if [ -n "$VAULT_ROOT_TOKEN" ]; then
    vault token create -policy root -id $VAULT_ROOT_TOKEN
  fi
  if [ -f /custom-init.sh ]; then
    . /custom-init.sh
  fi
  if [ -f /init/custom-init.sh ]; then
    . /init/custom-init.sh
  fi

  # forget the root token, now that we don't need it anymore
  unset VAULT_TOKEN

  # add a file to mark that the init has been done
  touch /vault/file/init.done

  echo "restarting vault with the standard configuration"
  kill %1
  wait %1
fi

if [ -z "$(ls -A /extra/config)" ]; then
  cp -r /extra/config/* /vault/config/
fi

if [ -f /vault/file/init.log ]; then
  # the unseal key is available on the disk, lets use it
  vault server -config /vault/config &
  dockerize -wait tcp://localhost:8200
  export VAULT_ADDR='http://127.0.0.1:8200'
  UNSEAL_KEY=$(sed 's/^Unseal Key 1: \(.*\)$/\1/' < /vault/file/init.log | head -n 1)
  vault operator unseal "$UNSEAL_KEY"
  wait %1
else
  exec vault server -config /vault/config
fi
