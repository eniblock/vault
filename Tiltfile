#!/usr/bin/env python

config.define_bool("no-volumes")
cfg = config.parse()

k8s_yaml(
    helm(
        'helm/vault',
        values=['./helm/vault/values-dev.yaml'],
        name="vault",
    )
)
custom_build(
    'eniblock/vault',
    'earthly +docker --ref=$EXPECTED_REF',
    ['.'],
)
k8s_resource('vault', port_forwards='8200')

local_resource('helm lint',
               'docker run --rm -t -v $PWD:/app registry.gitlab.com/xdev-tech/build/helm:3.1' +
               ' lint vault helm/vault --values helm/vault/values-dev.yaml',
               'helm/vault/', allow_parallel=True)

if config.tilt_subcommand == 'down' and not cfg.get("no-volumes"):
  local('kubectl --context ' + k8s_context() + ' delete pvc --selector=app.kubernetes.io/instance=vault --wait=false')
