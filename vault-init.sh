#!/usr/bin/env sh

VAULT_START_TIMEOUT="${VAULT_START_TIMEOUT:-10s}"

# make sure to stop if any of the command run in this script fail
set -e
if [ "$VAULT_DEBUG" == "true" ]; then
  set -x
  err_handler() {
    [ $? -eq 0 ] && exit
    echo 'Error raised. Sleeping 5 minutes before exiting to give you some time to debug.'
    sleep 300
  }
  trap 'err_handler' EXIT
fi

# copy extra configuration from the config map
for f in $(ls /extra/config); do
  cat /extra/config/$f > /vault/config/$f
done

if [ ! -f /vault/file/init.done ]; then
  if [ -n "$VAULT_INIT_TOKEN" ]; then
    # try to write something in vault, in order to be sure we'll be able to do that once
    # the local vault will be initialized
    env VAULT_TOKEN=$VAULT_INIT_TOKEN VAULT_ADDR=$VAULT_INIT_URL vault kv put $VAULT_INIT_PATH/vault "check=true"
  fi

  mkdir -p /dev/shm/vault/config
  cp -r /vault/config/* /dev/shm/vault/config/
  # override the listener with one restricted to 127.0.0.1
  cp /listener-init.hcl /dev/shm/vault/config/listener.hcl
  vault server -config /dev/shm/vault/config &
  export VAULT_ADDR='http://127.0.0.1:8201'
  dockerize -wait tcp://127.0.0.1:8201 -timeout "${VAULT_START_TIMEOUT}"

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

if [ -f /vault/file/init.log ]; then
  # the unseal key is available on the disk, lets use it
  vault server -config /vault/config &
  dockerize -wait tcp://127.0.0.1:8200 -timeout "${VAULT_START_TIMEOUT}"
  export VAULT_ADDR='http://127.0.0.1:8200'
  UNSEAL_KEY=$(sed 's/^Unseal Key 1: \(.*\)$/\1/' < /vault/file/init.log | head -n 1)
  vault operator unseal "$UNSEAL_KEY"
  wait %1
else
  exec vault server -config /vault/config
fi
