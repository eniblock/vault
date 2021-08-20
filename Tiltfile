#!/usr/bin/env python

if config.tilt_subcommand == 'up':
    docker_config = decode_json(local('clk k8s -c ' + k8s_context() + ' docker-credentials -d gitlab-registry', quiet=True))

k8s_yaml(
    helm(
        'helm/vault',
        values=['./helm/vault/values-dev.yaml'],
        name="vault",
    )
)
docker_build('registry.gitlab.com/xdev-tech/xdev-enterprise-business-network/vault', '.')
k8s_resource('vault', port_forwards='8200')

local_resource('helm lint',
               'docker run --rm -t -v $PWD:/app registry.gitlab.com/the-blockchain-xdev/xdev-product/build-images/helm:1.3.0' +
               ' lint helm/vault --values helm/vault/values-dev.yaml',
               'helm/vault/')
