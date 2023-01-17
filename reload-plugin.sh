#!/usr/bin/env sh

set -e
set -x

plugin_name=${1}
shift

if test -z "${VAULT_ADDR}"
then
    VAULT_ADDR='http://127.0.0.1:8200'
fi

set -u

export VAULT_ADDR
export VAULT_TOKEN="${VAULT_ROOT_TOKEN}"

HASH=$(sha256sum /vault/plugins/"${plugin_name}" | cut -f1 -d' ')

vault_tss_already_registered () {
    vault list sys/plugins/catalog/secret | grep -q "^${plugin_name}$"
}

vault_tss_registered_hash () {
    vault plugin info -field sha256 secret "${plugin_name}"
}

if vault_tss_already_registered && test "$(vault_tss_registered_hash)" = "${HASH}"
then
    echo "Vault plugin ${plugin_name} already registered and up-to-date" >&2
else
    vault plugin register -sha256 "${HASH}" "${plugin_name}"
    vault plugin reload -plugin "${plugin_name}"
    if vault secrets list | grep -q "^${plugin_name}/"
    then
        vault secrets disable "${plugin_name}"
    fi

    vault secrets enable -path "${plugin_name}" -description "From plugin '${plugin_name}'" "$@" "${plugin_name}"
fi
