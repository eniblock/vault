VERSION 0.6

dockerize:
    FROM alpine
    RUN apk add curl
    RUN curl -sL https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-alpine-linux-amd64-v0.6.1.tar.gz | tar xvzC /usr/bin
    SAVE ARTIFACT /usr/bin/dockerize

docker:
    FROM vault:1.12.2
    COPY +dockerize/dockerize /usr/bin/dockerize
    COPY vault-init.sh /
    COPY wait-for-vault.sh /
    COPY listener.hcl backend.hcl /vault/config/
    COPY listener-init.hcl /
    ENV VAULT_INIT_URL=https://vault.theblockchainxdev.com
    ENV VAULT_START_TIMEOUT=10s
    CMD /vault-init.sh
    ARG tag=latest
    ARG ref=eniblock/vault:${tag}
    SAVE IMAGE --push ${ref}
