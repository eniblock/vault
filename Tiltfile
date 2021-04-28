#!/usr/bin/env python

k8s_yaml(
    helm(
        'helm/vault',
        values=['./helm/vault/values-dev.yaml'],
        name="vault",
    )
)
docker_build('registry.gitlab.com/the-blockchain-xdev/xdev-product/enterprise-business-network/vault', '.')
k8s_resource('vault', port_forwards='8200')
