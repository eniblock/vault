#!/usr/bin/env sh

set -eu
set -x

plugin_name=${1}

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="${VAULT_ROOT_TOKEN}"

HASH=$(sha256sum /vault/plugins/"${plugin_name}" | cut -f1 -d' ')

vault plugin register -sha256 "${HASH}" "${plugin_name}"
vault plugin reload -plugin "${plugin_name}"
if vault secrets list | grep -q "^${plugin_name}/"
then
  vault secrets disable "${plugin_name}"
fi

vault secrets enable -path "${plugin_name}" -description 'From plugin "${plugin_name}"' "$@" "${plugin_name}"
