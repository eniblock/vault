# Vault

Create gitlab registry secret
```shell script
kubectl create secret docker-registry gitlab-registry --docker-server=registry.gitlab.com --docker-username=DOCKER_USER --docker-password=DOCKER_PASSWORD --docker-email=DOCKER_EMAIL
```

Install
```shell script
helm install vault ./helm/vault --values ./helm/vault/values-dev.yaml
```