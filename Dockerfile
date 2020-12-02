FROM alpine as dockerize-builder
RUN apk add curl
RUN curl -sL https://github.com/jwilder/dockerize/releases/download/v0.6.1/dockerize-alpine-linux-amd64-v0.6.1.tar.gz | tar xvzC /usr/bin

FROM vault:1.4.3
COPY --from=dockerize-builder /usr/bin/dockerize /usr/bin/dockerize
COPY vault-init.sh /
COPY config.json /vault/config/
ENV VAULT_INIT_URL=https://vault.theblockchainxdev.com
CMD /vault-init.sh
